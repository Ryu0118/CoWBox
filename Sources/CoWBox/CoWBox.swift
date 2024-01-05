import Foundation

@propertyWrapper
public struct CoWBox<State> {
    private class Storage: @unchecked Sendable {
        var state: State

        init(state: State) {
            self.state = state
        }
    }

    private var storage: Storage

    public init(wrappedValue: State) {
        storage = Storage(state: wrappedValue)
    }

    public var wrappedValue: State {
        get { storage.state }
        set {
            if !isKnownUniquelyReferenced(&storage) {
                storage = Storage(state: storage.state)
            }
            storage.state = newValue
        }
    }

    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }

    func sharesStorage(with other: Self) -> Bool {
        storage === other.storage
    }
}

extension CoWBox: Equatable where State: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sharesStorage(with: rhs)
            || lhs.wrappedValue == rhs.wrappedValue
    }
}

extension CoWBox: Hashable where State: Hashable {
    public func hash(into hasher: inout Hasher) {
        wrappedValue.hash(into: &hasher)
    }
}

extension CoWBox: Sendable where State: Sendable {}

extension CoWBox: Decodable where State: Decodable {
    public init(from decoder: Decoder) throws {
        do {
            try self.init(wrappedValue: decoder.singleValueContainer().decode(State.self))
        } catch {
            try self.init(wrappedValue: .init(from: decoder))
        }
    }
}

extension CoWBox: Encodable where State: Encodable {
    public func encode(to encoder: Encoder) throws {
        do {
            var container = encoder.singleValueContainer()
            try container.encode(wrappedValue)
        } catch {
            try wrappedValue.encode(to: encoder)
        }
    }
}

extension CoWBox: CustomReflectable {
    public var customMirror: Mirror {
        Mirror(reflecting: wrappedValue as Any)
    }
}
