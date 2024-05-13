//
//  File.swift
//  
//
//  Created by Alex Antonyuk on 13.05.2024.
//

import Foundation
import SwiftSyntax

extension TokenKind {
    var parameterValue: String? {
        if case .stringSegment(let string) = self {
            return string
        }
        return nil
    }
}
