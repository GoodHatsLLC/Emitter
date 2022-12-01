import Disposable
import EmitterInterface

extension Emitter {
    public func filter(
        _ evaluator: @escaping @MainActor (Output) -> Bool
    ) -> some Emitter<Output> {
        Emitters.Filter(upstream: self, evaluator: evaluator)
    }
}

// MARK: - Emitters.Filter

extension Emitters {
    // MARK: - Filter

    @MainActor
    public struct Filter<Upstream: Emitter, Output: Sendable>: Emitter
        where Upstream.Output == Output
    {

        @MainActor
        public init(
            upstream: Upstream,
            evaluator: @escaping @MainActor (Output) -> Bool
        ) where Upstream.Output == Output {
            self.evaluator = evaluator
            self.upstream = upstream
        }

        public let evaluator: @MainActor (Output) -> Bool
        public let upstream: Upstream

        public func subscribe<S: Subscriber>(_ subscriber: S)
            -> AnyDisposable
            where S.Value == Output
        {
            upstream.subscribe(Sub<S>(downstream: subscriber, evaluator: evaluator))
        }

        private struct Sub<Downstream: Subscriber>: Subscriber
            where Downstream.Value == Output
        {
            fileprivate init(downstream: Downstream, evaluator: @escaping @MainActor (Output) -> Bool) {
                self.downstream = downstream
                self.evaluator = evaluator
            }

            fileprivate func receive(emission: Emission<Output>) {
                let newEmission: Emission<Output>?
                switch emission {
                case .value(let value):
                    if evaluator(value) {
                        newEmission = .value(value)
                    } else {
                        newEmission = nil
                    }
                case _:
                    newEmission = emission
                }
                if let newEmission {
                    downstream.receive(emission: newEmission)
                }
            }

            private let downstream: Downstream
            private let evaluator: @MainActor (Output)
                -> Bool

        }

    }
}
