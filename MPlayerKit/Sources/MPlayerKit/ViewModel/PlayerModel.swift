//
//  PlayerModel.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/23/24.
//
@preconcurrency import AVKit
import MediaPlayer
import Combine
import os

private let logger = Logger(subsystem: "com.wyndot.MPlayerKit", category: "PlayerModel")

public enum PlayerState {
    case playing
    case paused (reason: PlayerPauseReason)
    
    var isPlaying: Bool {
        switch self {
            case .playing: true
            default: false
        }
    }
}

public enum PlayerPauseReason {
    case userInitiated
    case interrupted
    case toMinimizeStalls
    case evaluatingBufferRate
    case buffering
    case endOfMedia
    case error(Error)
}

public enum PlayerPresentation: Equatable {
    case none
    case fullscreen(autoplay: Bool)
    case inline
}

public enum PlayerError: Error {
    case notAvailable
    case invalidImageFormat
}

@MainActor
public class PlayerModel {
    @Published public var subtitle: AVMediaSelectionOption? {
        didSet {
            guard subtitle != oldValue else { return }
            selectSubtitles(subtitle)
        }
    }
    @Published public var audio: AVMediaSelectionOption? {
        didSet {
            guard audio != oldValue else { return }
            selectAudio(audio)
        }
    }
    @Published public var languages: [AVMediaSelectionOption]? {
        didSet { }
    }
    @Published private(set) var availableSubtitles: AVMediaSelectionGroup?
    @Published private(set) var availableAudios: AVMediaSelectionGroup?
    @Published private(set) var availableLanguages: [AVMediaSelectionGroup]?
    @Published private(set) var state: PlayerState = .paused(reason: .userInitiated)
    @Published private(set) var currentItem: (any Playable)?
    @Published private(set) var duration: CMTime?
    @Published private(set) var currentTime: CMTime?
    @Published private(set) var aspectRatio: CGFloat = 16.0 / 9.0
    @Published public var presentation: PlayerPresentation = .none
    @Published private(set) var isPiPActive: Bool = false
    @Published private(set) var isPiPPossible: Bool = false
    private(set) var player: AVPlayer = AVPlayer()
    private(set) var pipControler: AVPictureInPictureController?
    private var playerTimeControlStatusObservationToken: NSKeyValueObservation?
    private var pipActiveObservationToken: NSKeyValueObservation?
    private var pipPossibleObservationToken: NSKeyValueObservation?
    private var playerItemDidEndObservationTask: Task<Void, Never>?
#if os(iOS)
    private var nowPlayingSession: NowPlayingSession = .init()
#endif
#if !os(macOS)
    private var playerAudioInterruptionObservationTask: Task<Void, Never>?
    private var interruption: InterruptionResult?
#endif
    private var playerPeriodicTimeObservationToken: Any?
    
    public init() {
        logger.debug("\(Self.self) Initialized")
        #if os(iOS)
        nowPlayingSession.active(player: player)
        #endif
        startObservingPlayback()
    }
    
    deinit {
        Task { @MainActor [weak self] in
            self?.stopObservingPlayback()
        }
        logger.debug("\(Self.self) Deinitialized")
    }
    
    /**
     * Load the Playable meida
     *
     * - Parameters:
     *  - item: The playable media item
     */
    public func load(_ item: any Playable) async {
        let playerItem = item.playerItem()
        let externalMetadata = await externalMetadata(for: item)
        let extraMetadata = item.extraExternalMetadata()
        playerItem.externalMetadata = externalMetadata + extraMetadata
        currentItem = item
        player.replaceCurrentItem(with: playerItem)
        duration = try? await playerItem.asset.load(.duration)
        aspectRatio = await playerItem.loadAspectRatio()
        availableSubtitles = try? await playerItem.availableSutitleSelectionGroup()
        availableAudios = try? await playerItem.availableAudioSelectionGroup()
        availableLanguages = try? await playerItem.availableLanguageSelectionGroup()
        if let availableSubtitles {
            subtitle = playerItem.currentMediaSelection.selectedMediaOption(in: availableSubtitles)
        }
        if let availableAudios {
            audio = playerItem.currentMediaSelection.selectedMediaOption(in: availableAudios)
        }
        if let availableLanguages {
            languages = playerItem.currentLanguageOptions(in: availableLanguages)
        }
        currentTime = player.currentTime()
        #if os(iOS)
        publishNowPlayingStaticMetadata()
        #endif
    }
    public func play() {
        setMoviePlaybackAudioSession()
        player.play()
    }
    public func pause() {
        player.pause()
        resetMoviePlaybackAudioSession()
    }
    public func seek(_ to: CMTime) { player.seek(to: to) }
    public func skip(_ seconds: TimeInterval) {
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let currentTime = player.currentTime()
        seek(currentTime + time)
    }
}

// Observation
extension PlayerModel {
    /**
     * Start observing playback. This is including observing the player time control status, player did play to the end, audio session interruption, and the periodic time observation
     */
    private func startObservingPlayback() {
        logger.debug("Starting observation of player")
        startObservingPlayerTimeControlStatus()
        startObservingPlayerPlayToEndTime()
        startObservingPlayerPeriodicTime()
        #if !os(macOS)
        startObservingAudioSessionInterruption()
        #endif
    }
    /**
     * Stop observing playback
     */
    private func stopObservingPlayback() {
        playerTimeControlStatusObservationToken?.invalidate()
        playerItemDidEndObservationTask?.cancel()
        stopObservingPlayerPeriodicTime()
        stopObservePiPStatus()
        #if !os(macOS)
        playerAudioInterruptionObservationTask?.cancel()
        #endif
        logger.debug("Stopped observation of player")
    }
    
    /**
     * Start observing the player time control status
     */
    private func startObservingPlayerTimeControlStatus() {
        guard playerTimeControlStatusObservationToken == nil else { return }
        playerTimeControlStatusObservationToken = player.observe(\.timeControlStatus) { observed, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch observed.timeControlStatus {
                    case .paused:
                        state = .paused(reason: interruption != nil ? .interrupted : .userInitiated)
                    case .playing:
                        state = .playing
                    case .waitingToPlayAtSpecifiedRate:
                        switch observed.reasonForWaitingToPlay {
                            case .toMinimizeStalls:
                                state = .paused(reason: .toMinimizeStalls)
                            case .evaluatingBufferingRate:
                                state = .paused(reason: .evaluatingBufferRate)
                            default:
                                state = .paused(reason: .buffering)
                        }
                    @unknown default: break
                }
            }
        }
    }
    
    /**
     * Start observing player played the media to the end
     */
    private func startObservingPlayerPlayToEndTime() {
        playerItemDidEndObservationTask?.cancel()
        playerItemDidEndObservationTask = Task.detached { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .AVPlayerItemDidPlayToEndTime, object: nil) {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.state = .paused(reason: .endOfMedia)
                }
            }
        }
    }
    
    /**
     * Start observing the audio session interruption
     */
    private func startObservingAudioSessionInterruption() {
        playerAudioInterruptionObservationTask?.cancel()
        playerAudioInterruptionObservationTask = Task.detached { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: AVAudioSession.interruptionNotification) {
                guard let result = InterruptionResult(notification) else { return }
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    if result.type == .began {
                        self.interruption = result
                        self.resetMoviePlaybackAudioSession()
                    } else if result.type == .ended {
                        self.interruption = nil
                        if result.options == .shouldResume {
                            self.setMoviePlaybackAudioSession()
                            self.player.play()
                        }
                    }
                }
            }
        }
    }
    
    /**
     * Start the player periodic time observation
     */
    private func startObservingPlayerPeriodicTime() {
        stopObservingPlayerPeriodicTime()
        playerPeriodicTimeObservationToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                currentTime = time
                #if os(iOS)
                publishNowPlayingDynamicMetadata()
                #endif 
            }
        }
    }
    
    /**
     * Stop the player periodic time observation
     */
    private func stopObservingPlayerPeriodicTime() {
        guard let playerPeriodicTimeObservationToken else { return }
        player.removeTimeObserver(playerPeriodicTimeObservationToken)
    }
}

// Subtitles & Audio Selection
extension PlayerModel {
    /**
     * Select the subtitle option
     *
     * - Parameters:
     *  - option: The selected subtitle option
     */
    func selectSubtitles(_ option: AVMediaSelectionOption?) {
        guard let currentItem = player.currentItem, let availableSubtitles else { return }
        currentItem.select(option, in: availableSubtitles)
        subtitle = currentItem.currentMediaSelection.selectedMediaOption(in: availableSubtitles)
    }
    
    /**
     * Select the audio option
     *
     * - Parameters:
     *  - option: The selected audio option
     */
    func selectAudio(_ option: AVMediaSelectionOption?) {
        guard let currentItem = player.currentItem, let availableAudios else { return }
        currentItem.select(option, in: availableAudios)
        audio = currentItem.currentMediaSelection.selectedMediaOption(in: availableAudios)
    }
}

// Picture In Picture
extension PlayerModel{
    internal func createPIPController(_ playerLayer: AVPlayerLayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        pipControler = AVPictureInPictureController(playerLayer: playerLayer)
        startObservePiPStatus()
    }
    
    /**
     * Toggle the Picture In Picture
     *
     */
    public func togglePiP() {
        guard let pipControler else { return }
        if pipControler.isPictureInPictureActive {
            pipControler.stopPictureInPicture()
        } else  {
            pipControler.startPictureInPicture()
        }
    }
    
    private func startObservePiPStatus() {
        pipActiveObservationToken?.invalidate()
        pipActiveObservationToken = pipControler?.observe(\.isPictureInPictureActive, changeHandler: { observed, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                isPiPActive = observed.isPictureInPictureActive
            }
        })
        pipPossibleObservationToken?.invalidate()
        pipPossibleObservationToken = pipControler?.observe(\.isPictureInPicturePossible, changeHandler: { observed, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                isPiPPossible = observed.isPictureInPicturePossible
            }
        })
    }
    
    private func stopObservePiPStatus() {
        pipActiveObservationToken?.invalidate()
        pipActiveObservationToken = nil
        pipPossibleObservationToken?.invalidate()
        pipPossibleObservationToken = nil
    }
}

// Audio
extension PlayerModel {
    private func setMoviePlaybackAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        } catch {
            logger.error("Failed to Set Audio Session to moviePlayback")
        }
    }
    
    private func resetMoviePlaybackAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            logger.error("Failed to Reset moviePlayback Audio Session")
        }
    }
}

// NowPlaying Info
extension PlayerModel {
    /**
     * External metadata for the AVPlayerViewController
     */
    private func externalMetadata(for playable: any Playable) async -> [AVMetadataItem] {
        var mapping: [AVMetadataIdentifier: Any?] = [
            .commonIdentifierTitle: playable.title,
            .commonIdentifierDescription: playable.synopsis,
            .commonIdentifierCreationDate: playable.releaseYear,
            .iTunesMetadataContentRating: playable.contentRating,
            .quickTimeMetadataGenre: playable.genres
        ]
        mapping[.commonIdentifierArtwork] = try? await playable.poster?.artwork(for: .portrait)
        
        return mapping.compactMap({ createMetadatItem(for: $0, value: $1)})
    }
    
#if os(iOS)
    /**
     * Publish the now playing metadata which NOT changing during playing to the Media Player Now Playing Session
     */
    private func publishNowPlayingStaticMetadata() {
        Task { [weak self] in
            guard let self else { return }
            let metadata = try await nowPlayingStaticMetadata()
            nowPlayingSession.publish(metadata: metadata, isPlaying: state.isPlaying)
        }
    }
    
    /**
     * Publish the now playing metadata which changing during playing to the Media Player Now Playing Session
     */
    private func publishNowPlayingDynamicMetadata() {
        Task { [weak self] in
            guard let self else { return }
            let dynamicMetadat = try nowPlayingDynamicMetadata()
            nowPlayingSession.publish(metadata: dynamicMetadat, isPlaying: state.isPlaying)
        }
    }
    
    /**
     * The dictionary contains  the now playing metadata which are not changing during the playing
     */
    private func nowPlayingStaticMetadata() async throws -> [String: Any] {
        guard let currentItem else { throw PlayerError.notAvailable }
        var metadata: [String: Any] = [MPNowPlayingInfoPropertyAssetURL: currentItem.asset,
                                   MPNowPlayingInfoPropertyIsLiveStream: currentItem.isLive,
                                      MPNowPlayingInfoPropertyMediaType: currentItem.isVideo ? MPNowPlayingInfoMediaType.video.rawValue : MPNowPlayingInfoMediaType.audio.rawValue,
                                               MPMediaItemPropertyTitle: currentItem.title,
                                            MPMediaItemPropertyComments: currentItem.synopsis ?? ""
        ]
        if let artworkData = try? await currentItem.poster?.artwork(for: .portrait), let uiImage = UIImage(data: artworkData) {
            metadata[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: uiImage)
        }
        return metadata
    }
    
    /**
     * The dictionary contains the now playing metadata which are chaning during the playing
     */
    private func nowPlayingDynamicMetadata() throws -> [String: Any] {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay else { throw PlayerError.notAvailable }
        
        var mpLanguageOptions = [MPNowPlayingInfoLanguageOptionGroup]()
        var mpCurrentSelectionOptions = [MPNowPlayingInfoLanguageOption]()
        if let languages, let availableLanguages {
            mpLanguageOptions = availableLanguages.map({ $0.makeNowPlayingInfoLanguageOptionGroup() })
            mpCurrentSelectionOptions = languages.compactMap({ $0.makeNowPlayingInfoLanguageOption() })
        }
        
        return [MPNowPlayingInfoPropertyPlaybackRate: player.rate,
         MPNowPlayingInfoPropertyElapsedPlaybackTime: CMTimeGetSeconds(currentItem.currentTime()),
                 MPMediaItemPropertyPlaybackDuration: CMTimeGetSeconds(currentItem.duration),
      MPNowPlayingInfoPropertyCurrentLanguageOptions: mpCurrentSelectionOptions,
    MPNowPlayingInfoPropertyAvailableLanguageOptions: mpLanguageOptions]
    }
#endif
    
    private func createMetadatItem(for identifier: AVMetadataIdentifier, value: Any?) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        return item
    }
}
