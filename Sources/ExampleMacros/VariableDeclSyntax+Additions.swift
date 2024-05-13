//
//  File.swift
//  
//
//  Created by Alex Antonyuk on 06.05.2024.
//

import SwiftSyntax

extension VariableDeclSyntax {
    var identifierPattern: IdentifierPatternSyntax? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)
    }

    var isInstance: Bool {
        for modifier in modifiers {
            for token in modifier.tokens(viewMode: .all) {
                if token.tokenKind == .keyword(.static) || token.tokenKind == .keyword(.class) {
                    return false
                }
            }
        }
        return true
    }

    var identifier: TokenSyntax? {
        identifierPattern?.identifier
    }

    var type: TypeSyntax? {
        bindings.first?.typeAnnotation?.type
    }

    func accessorsMatching(_ predicate: (TokenKind) -> Bool) -> [AccessorDeclSyntax] {
        let accessors: [AccessorDeclListSyntax.Element] = bindings.compactMap { patternBinding in
            switch patternBinding.accessorBlock?.accessors {
            case let .accessors(accessors):
                return accessors
            default:
                return nil
            }
        }.flatMap { $0 }
        return accessors.compactMap { predicate($0.accessorSpecifier.tokenKind) ? $0 : nil }
    }

    var willSetAccessors: [AccessorDeclSyntax] {
        accessorsMatching { $0 == .keyword(.willSet) }
    }
    var didSetAccessors: [AccessorDeclSyntax] {
        accessorsMatching { $0 == .keyword(.didSet) }
    }

    var isComputed: Bool {
        if accessorsMatching({ $0 == .keyword(.get) }).count > 0 {
            return true
        } else {
            return bindings.contains { binding in
                if case .getter = binding.accessorBlock?.accessors {
                    return true
                } else {
                    return false
                }
            }
        }
    }

    var isImmutable: Bool {
        return bindingSpecifier.tokenKind == .keyword(.let)
    }

    func isEquivalent(to other: VariableDeclSyntax) -> Bool {
        if isInstance != other.isInstance {
            return false
        }
        return identifier?.text == other.identifier?.text
    }

    var initializer: InitializerClauseSyntax? {
        bindings.first?.initializer
    }

    func hasMacroApplication(_ name: String) -> Bool {
        for attribute in attributes {
            switch attribute {
            case .attribute(let attr):
                if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
                    return true
                }
            default:
                break
            }
        }
        return false
    }

    func firstAttribute(for name: String) -> AttributeSyntax? {
        for attribute in attributes {
            switch attribute {
            case .attribute(let attr):
                if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
                    return attr
                }
            default:
                break
            }
        }
        return nil
    }
}
