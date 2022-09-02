//
// BoolEX.swift
// Copyright (c) 2022 LeitnerBox
//
// Created by Hamed Hosseini on 8/14/22.

import SwiftUI

extension Bool {
    static var iOS: Bool {
        guard #available(iOS 15, *) else {
            // It's macOS
            return false
        }
        return true
    }
}
