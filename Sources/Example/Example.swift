// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(accessor, names: named(init), named(_read), named(set), named(_modify))
@attached(peer, names: prefixed(_))
public macro Test() = #externalMacro(module: "ExampleMacros", type: "TestMacro")
