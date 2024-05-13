import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct TestMacro {}

// MARK: -
extension TestMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard
            let property = declaration.as(VariableDeclSyntax.self),
            property.canHeapify
        else {
            return []
        }

        let wrapped = DeclSyntax(
            property.privateWrapped()
        )
        return [
            wrapped
        ]
    }
}

// MARK: -
extension TestMacro: AccessorMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        guard
            let property = declaration.as(VariableDeclSyntax.self),
            property.canHeapify,
            let identifier = property.identifier?.trimmed
        else {
            return []
        }

        let initAccessor: AccessorDeclSyntax =
        """
        @storageRestrictions(initializes: _\(identifier))
        init(initialValue) {
        _\(identifier) = SomePropertyWrapper(wrappedValue: initialValue)
        }
        """

        let getAccessor: AccessorDeclSyntax =
        """
        get {
        _$observationRegistrar.access(self, keyPath: \\.\(identifier))
        return _\(identifier).wrappedValue
        }
        """

        let setAccessor: AccessorDeclSyntax =
        """
        set {
        _$observationRegistrar.mutate(self, keyPath: \\.\(identifier), &_\(identifier).wrappedValue, newValue, _$isIdentityEqual)
        }
        """

        // TODO: _modify accessor?

        return [
            initAccessor,
            getAccessor,
            setAccessor
        ]
    }
}

extension VariableDeclSyntax {
    var canHeapify: Bool {
        !isComputed && isInstance && !isImmutable
    }

    fileprivate func privateWrapped() -> VariableDeclSyntax {
        var attributes = self.attributes
        // remove macro itself to prevent recursion
        for index in attributes.indices.reversed() {
            let attribute = attributes[index]
            switch attribute {
            case let .attribute(attribute):
                if attribute.attributeName.tokens(viewMode: .all).map(\.tokenKind) == [.identifier("Test")] {
                    attributes.remove(at: index)
                }
            default:
                break
            }
        }

        return VariableDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: attributes,
            modifiers: modifiers.privatePrefixed("_"),
            bindingSpecifier: TokenSyntax(
                bindingSpecifier.tokenKind, trailingTrivia: .space,
                presence: .present
            ),
            bindings: bindings.privateWrapped,
            trailingTrivia: trailingTrivia
        )
    }
}

extension PatternBindingListSyntax {
    fileprivate var privateWrapped: PatternBindingListSyntax {
        var bindings = self
        for index in bindings.indices {
            var binding = bindings[index]
            if let optionalType = binding.typeAnnotation?.type.as(OptionalTypeSyntax.self) {
                binding.typeAnnotation = nil
                binding.initializer = InitializerClauseSyntax(
                    value: FunctionCallExprSyntax(
                        calledExpression: optionalType.wrappedType.presentationWrapped,
                        leftParen: .leftParenToken(),
                        arguments: [
                            LabeledExprSyntax(
                                label: "wrappedValue",
                                expression: binding.initializer?.value ?? ExprSyntax(NilLiteralExprSyntax())
                            )
                        ],
                        rightParen: .rightParenToken()
                    )
                )
            } else if let varType = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self) {
                binding.typeAnnotation = TypeAnnotationSyntax(type: TypeSyntax(stringLiteral: "Example.SomePropertyWrapper<\(varType.name)>"))
            }
            if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                bindings[index] = PatternBindingSyntax(
                    leadingTrivia: binding.leadingTrivia,
                    pattern: IdentifierPatternSyntax(
                        leadingTrivia: identifier.leadingTrivia,
                        identifier: identifier.identifier.privatePrefixed("_"),
                        trailingTrivia: identifier.trailingTrivia
                    ),
                    typeAnnotation: binding.typeAnnotation,
                    initializer: binding.initializer,
                    accessorBlock: binding.accessorBlock,
                    trailingComma: binding.trailingComma,
                    trailingTrivia: binding.trailingTrivia
                )
            }
        }

        return bindings
    }
}

extension TokenSyntax {
    func privatePrefixed(_ prefix: String) -> TokenSyntax {
        switch tokenKind {
        case .identifier(let identifier):
            return TokenSyntax(
                .identifier(prefix + identifier), leadingTrivia: leadingTrivia,
                trailingTrivia: trailingTrivia, presence: presence)
        default:
            return self
        }
    }
}

extension DeclModifierListSyntax {
    func privatePrefixed(_ prefix: String) -> DeclModifierListSyntax {
        let modifier: DeclModifierSyntax = DeclModifierSyntax(name: "private", trailingTrivia: .space)
        return [modifier]
        + filter {
            switch $0.name.tokenKind {
            case .keyword(let keyword):
                switch keyword {
                case .fileprivate, .private, .internal, .public, .package:
                    return false
                default:
                    return true
                }
            default:
                return true
            }
        }
    }

    init(keyword: Keyword) {
        self.init([DeclModifierSyntax(name: .keyword(keyword))])
    }
}

extension TypeSyntax {
    fileprivate var presentationWrapped: GenericSpecializationExprSyntax {
        GenericSpecializationExprSyntax(
            expression: TypeExprSyntax(type: TypeSyntax(stringLiteral: "SomePropertyWrapper")),
            genericArgumentClause: GenericArgumentClauseSyntax(
                arguments: [
                    GenericArgumentSyntax(
                        argument: OptionalTypeSyntax(wrappedType: self)
                    )
                ]
            )
        )
    }
}


@main
struct ExamplePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TestMacro.self,
    ]
}

