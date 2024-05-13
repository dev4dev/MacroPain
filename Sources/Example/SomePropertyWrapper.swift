//
//  File.swift
//  
//
//  Created by Alex Antonyuk on 13.05.2024.
//

import Foundation

@propertyWrapper
public struct SomePropertyWrapper<Value> {
    private var _box: Value

    public var wrappedValue: Value {
        _read { yield _box }
        set { _box = newValue }
        _modify {
            yield &_box
        }
    }

    public init(wrappedValue: Value) {
        self._box = wrappedValue
    }
}
