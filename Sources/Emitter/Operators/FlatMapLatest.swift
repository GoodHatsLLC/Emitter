import Disposable
import EmitterInterface

extension Emitter {
    public func flatMapLatest<NewOutput: Sendable>(producer: @escaping @MainActor (Output) -> some Emitter<NewOutput>)
        -> some Emitter<NewOutput> {
        FlatMapLatest(upstream: self, producer: producer)
    }
}

// MARK: - FlatMapLatest

@MainActor
struct FlatMapLatest<Input: Sendable, Output: Sendable>: Emitter {

    init<Upstream: Emitter>(
        upstream: Upstream,
        producer: @escaping @MainActor (Input) -> some Emitter<Output>
    ) where Upstream.Output == Input {
        self.producer = { producer($0).erase() }
        self.upstream = upstream
    }

    @MainActor
    final class Sub<Downstream: Subscriber>: Subscriber
        where Downstream.Value == Output {

        init<Upstream: Emitter>(
            downstream: Downstream,
            upstream: Upstream,
            producer: @escaping @MainActor (Input) -> AnyEmitter<Output>
        ) where Upstream.Output == Input {
            self.downstream = downstream
            self.producer = producer
            self.upstream = upstream
        }

        @MainActor
        final class InnerSub<Downstream: Subscriber>: Subscriber
            where Downstream.Value == Output {
            init(
                downstream: Downstream
            ) {
                self.downstream = downstream
            }

            let downstream: Downstream
            var upstreamDidFinish = false

            func receive(emission: Emission<Output>) {
                switch emission {
                case .value(let value):
                    downstream.receive(emission: .value(value))
                case .finished:
                    downstream.receive(emission: .finished)
                case .failed(let error):
                    downstream.receive(emission: .failed(error))
                }
            }
        }

        let downstream: Downstream
        let producer: @MainActor (Input) -> AnyEmitter<Output>

        let upstream: any Emitter<Input>
        var current: InnerSub<Downstream>?
        var currentDisp: AnyDisposable?

        func receive(emission: Emission<Input>) {
            switch emission {
            case .value(let value):
                current?.receive(emission: .finished)
                currentDisp?.dispose()
                let inner = InnerSub(downstream: downstream)
                current = inner
                currentDisp = producer(value).subscribe(inner)
            case .finished:
                downstream.receive(emission: .finished)
            case .failed(let error):
                downstream.receive(emission: .failed(error))
            }
        }

    }

    let producer: @MainActor (Input) -> AnyEmitter<Output>
    let upstream: any Emitter<Input>

    func subscribe<S: Subscriber>(_ subscriber: S)
        -> AnyDisposable
        where S.Value == Output {
        upstream.subscribe(
            Sub<S>(
                downstream: subscriber,
                upstream: upstream,
                producer: producer
            )
        )
    }

}
