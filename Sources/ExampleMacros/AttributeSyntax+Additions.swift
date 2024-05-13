//
//  File.swift
//  
//
//  Created by Alex Antonyuk on 13.05.2024.
//

import Foundation
import SwiftSyntax

extension AttributeSyntax {
    var parameterValues: [String] {
        let args = arguments?.as(LabeledExprListSyntax.self) ?? []
        let segments = args.compactMap { $0.expression.as(StringLiteralExprSyntax.self)?.segments }
        return segments.compactMap { $0.first?.as(StringSegmentSyntax.self)?.content.tokenKind.parameterValue }
    }
}
