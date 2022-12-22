import Disposable
import EmitterInterface

extension Emitter {
    public func union<Other: Emitter>(
        _ other: Other
    ) -> some Emitter<Union.Of2<Output, Other.Output>>
        where Other.Output: Union.Unionable, Output: Union.Unionable
    {
        Emitters.Union(upstreamA: self, upstreamB: other)
    }
}

// MARK: - Emitters.Union

extension Emitters {

    public struct Union<UpstreamA: Emitter, UpstreamB: Emitter>: Emitter
        where UpstreamA.Output: EmitterInterface.Union.Unionable, UpstreamB.Output: EmitterInterface.Union.Unionable
    {

        public init(
            upstreamA: UpstreamA,
            upstreamB: UpstreamB
        ) {
            self.upstreamA = upstreamA
            self.upstreamB = upstreamB
        }

        public typealias Output = EmitterInterface.Union.Of2<UpstreamA.Output, UpstreamB.Output>

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
                upstreamA: UpstreamA,
                upstreamB: UpstreamB
            )
                -> AnyDisposable
            {
                let disposableA = upstreamA
                    .subscribe(
                        Proxy(
                            downstream: self,
                            joinInit: EmitterInterface.Union.Of2.a
                        )
                    )
                let disposableB = upstreamB
                    .subscribe(
                        Proxy(
                            downstream: self,
                            joinInit: EmitterInterface.Union.Of2.b
                        )
                    )
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

        private struct Proxy<UpstreamValue, Downstream: Subscriber>: Subscriber where Downstream.Value == Output {

            fileprivate init(
                downstream: Downstream,
                joinInit: @escaping (UpstreamValue) -> Output
            ) {
                self.downstream = downstream
                self.joinInit = joinInit
            }

            fileprivate func receive(emission: Emission<UpstreamValue>) {
                let forwarded: Emission<Output>
                switch emission {
                case .value(let value):
                    forwarded = .value(joinInit(value))
                case .finished:
                    forwarded = .finished
                case .failed(let error):
                    forwarded = .failed(error)
                }
                downstream.receive(emission: forwarded)
            }

            private let downstream: Downstream
            private let joinInit: (UpstreamValue) -> Output

        }

    }
}
