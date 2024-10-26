//
//  Notificaiton+Ext.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/23/24.
//
import AVFoundation

struct InterruptionResult {
    let type: AVAudioSession.InterruptionType
    let options: AVAudioSession.InterruptionOptions
    
    init?(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return nil }
        
        guard let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType,
              let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? AVAudioSession.InterruptionOptions else { return nil }
        type = typeValue
        options = optionsValue
    }
}
