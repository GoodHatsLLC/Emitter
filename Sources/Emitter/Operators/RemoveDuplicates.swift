import Disposable
import EmitterInterface

extension Emitter {
    public func removeDuplicates() -> some Emitter<Output>
        where Output: Equatable
    {
        Emitters.RemoveDuplicates(upstream: self)
    }
}

// MARK: - Emitters.RemoveDuplicates

extension Emitters {
    // MARK: - RemoveDuplicates

    public struct RemoveDuplicates<Upstream: Emitter, Output: Sendable>: Emitter where Output: Equatable,
        Upstream.Output == Output
    {

        public init(
            upstream: Upstream
        ) {
            self.upstream = upstream
        }

        public func subscribe<S: Subscriber>(_ subscriber: S)
            -> AnyDisposable
            where S.Value == Output, Output: Equatable
        {
            upstream.subscribe(Sub<S>(downstream: subscriber))
        }


        private final class Sub<Downstream: Subscriber>: Subscriber
            where Downstream.Value == Output, Output: Equatable
        {

            public init(downstream: Downstream) {
                self.downstream = downstream
            }

            public func receive(emission: Emission<Output>) {
                switch emission {
                case .value(let value):
                    if value != last {
                        last = value
                        downstream.receive(emission: emission)
                    }
                case _:
                    downstream.receive(emission: emission)
                }
            }

            private let downstream: Downstream
            private var last: Output?

        }

        private let upstream: Upstream

    }
}
