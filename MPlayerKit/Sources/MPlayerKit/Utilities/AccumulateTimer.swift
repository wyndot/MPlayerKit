//
//  AccumulateTimer.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/26/24.
//
import Foundation

actor AccumulateTimer {
    var timers: [String: Timer] = [:]
    
    func schedule(action: String, timeInterval: TimeInterval, perform: @Sendable @escaping () -> Void) {
        let timer = Timer(timeInterval: timeInterval, repeats: false, block: { [weak self] timer in
            perform()
            Task {
                await self?.remove(action: action)
            }
        })
        remove(action: action)
        timers[action] = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    func remove(action: String) {
        timers[action]?.invalidate()
        timers[action] = nil
    }
}
