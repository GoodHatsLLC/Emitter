import Disposable
import EmitterInterface

extension Emitter {
    public func merge<Other: Emitter>(
        _ other: Other
    ) -> some Emitter<Output> where Other.Output == Output {
        Emitters.Merge(upstreamA: self, upstreamB: other)
    }
}

// MARK: - Emitters.Merge

extension Emitters {
    // MARK: - Merge

    public struct Merge<UpstreamA: Emitter, UpstreamB: Emitter, Output: Sendable>: Emitter
        where UpstreamA.Output == Output, UpstreamB.Output == Output
    {

        public init(
            upstreamA: UpstreamA,
            upstreamB: UpstreamB
        ) {
            self.upstreamA = upstreamA
            self.upstreamB = upstreamB
        }

        public let upstreamA: UpstreamA
        public let upstreamB: UpstreamB

        public func subscribe<S: Subscriber>(
            _ subscriber: S
        )
            -> AnyDisposable
            where S.Value == Output
        {
            IntermediateSub<S>(downstream: subscriber)
                .subscribe(
                    upstreamA: upstreamA,
                    upstreamB: upstreamB
                )
        }


        private final class IntermediateSub<Downstream: Subscriber>: Subscriber
            where Downstream.Value == Output
        {

            fileprivate init(downstream: Downstream) {
                self.downstream = downstream
            }

            fileprivate let downstream: Downstream

            fileprivate func subscribe(
                upstreamA: some Emitter<Output>,
                upstreamB: some Emitter<Output>
            )
                -> AnyDisposable
            {
                let disposableA = upstreamA.subscribe(self)
                let disposableB = upstreamB.subscribe(self)
                let disposable = AnyDisposable {
                    disposableA.dispose()
                    disposableB.dispose()
                }
                self.disposable = disposable
                return disposable
            }

            fileprivate func receive(emission: Emission<Output>) {
                downstream.receive(emission: emission)

                switch emission {
                case .value: break
                case .finished,
                     .failed:
                    if let disposable {
                        disposable.dispose()
                    }
                }
            }

            private weak var disposable: AnyDisposable?

        }

    }
}
