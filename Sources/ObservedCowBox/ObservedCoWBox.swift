#if canImport(Perception)
    import Foundation
    import Perception

    @propertyWrapper
    public struct ObservedCoWBox<State>: Perceptible {
        @Perceptible
        final class Storage: @unchecked Sendable {
            var state: State

            init(state: State) {
                self.state = state
            }
        }

        private var storage: Storage

        public init(wrappedValue: State) {
            self.storage = Storage(state: wrappedValue)
        }

        public var wrappedValue: State {
            get {
                access(keyPath: \.storage)
                return storage.state
            }
            set {
                withMutation(keyPath: \.storage) {
                    if !isKnownUniquelyReferenced(&storage) {
                        storage = Storage(state: newValue)
                        return
                    }
                    storage.state = newValue
                }
            }
        }

        public var projectedValue: Self {
            get { self }
            set { self = newValue }
        }

        func sharesStorage(with other: Self) -> Bool {
            storage === other.storage
        }

        private let _$perceptionRegistrar = Perception.PerceptionRegistrar()

        internal nonisolated func access<Member>(
            keyPath: KeyPath<Self, Member>,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            _$perceptionRegistrar.access(self, keyPath: keyPath, file: file, line: line)
        }

        internal nonisolated func withMutation<Member, MutationResult>(
            keyPath: KeyPath<Self, Member>,
            _ mutation: () throws -> MutationResult
        ) rethrows -> MutationResult {
            try _$perceptionRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
        }
    }

    extension ObservedCoWBox: Equatable where State: Equatable {
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.sharesStorage(with: rhs)
                || lhs.wrappedValue == rhs.wrappedValue
        }
    }

    extension ObservedCoWBox: Hashable where State: Hashable {
        public func hash(into hasher: inout Hasher) {
            wrappedValue.hash(into: &hasher)
        }
    }

    extension ObservedCoWBox: Sendable where State: Sendable {}

    extension ObservedCoWBox: Decodable where State: Decodable {
        public init(from decoder: Decoder) throws {
            do {
                try self.init(wrappedValue: decoder.singleValueContainer().decode(State.self))
            } catch {
                try self.init(wrappedValue: .init(from: decoder))
            }
        }
    }

    extension ObservedCoWBox: Encodable where State: Encodable {
        public func encode(to encoder: Encoder) throws {
            do {
                var container = encoder.singleValueContainer()
                try container.encode(wrappedValue)
            } catch {
                try wrappedValue.encode(to: encoder)
            }
        }
    }

    extension ObservedCoWBox: CustomReflectable {
        public var customMirror: Mirror {
            Mirror(reflecting: wrappedValue as Any)
        }
    }

    #if canImport(Observation)
        extension ObservedCoWBox: Observable {}
    #endif
#endif
