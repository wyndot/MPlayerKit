//
//  Utilities.swift
//  MPlayerKit
//
//  Created by Michael Zhang on 10/31/24.
//
import UIKit

@MainActor @inlinable
public func deviceSpecificValue<T>(phone phoneValue: T, pad padValue: T, tv tvValue: T, `default` defaultValue: T) -> T {
    switch UIDevice.current.userInterfaceIdiom {
        case .phone: phoneValue
        case .pad: padValue
        case .tv: tvValue
        default: defaultValue
    }
}
