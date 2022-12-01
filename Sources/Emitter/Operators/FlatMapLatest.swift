import Disposable
import EmitterInterface

extension Emitter {

    public func flatMapLatest<NewOutput: Sendable>(producer: @escaping @MainActor (Output) -> some Emitter<NewOutput>)
        -> some Emitter<NewOutput>
    {
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
        where Downstream.Value == Output
    {

        init(
            downstream: Downstream,
            producer: @escaping @MainActor (Input) -> AnyEmitter<Output>
        ) {
            self.downstream = downstream
            self.producer = producer
        }

        let downstream: Downstream
        let producer: @MainActor (Input) -> AnyEmitter<Output>

        var subscription: AnyDisposable?

        func receive(emission: Emission<Input>) {
            switch emission {
            case .value(let value):
                subscribeToNewEmitter(producer(value))
            case .finished:
                downstream.receive(emission: .finished)
                subscription?.dispose()
            case .failed(let error):
                downstream.receive(emission: .failed(error))
                subscription?.dispose()
            }
        }

        func subscribeToNewEmitter(_ emitter: AnyEmitter<Output>) {
            subscription?.dispose()
            subscription = emitter
                .subscribe { [weak self] value in
                    self?.downstream.receive(emission: .value(value))
                } finished: { [weak self] in
                    self?.downstream.receive(emission: .finished)
                    self?.subscription?.dispose()
                } failed: { [weak self] error in
                    self?.downstream.receive(emission: .failed(error))
                    self?.subscription?.dispose()
                }
        }

    }

    func subscribe<S: Subscriber>(_ subscriber: S)
        -> AnyDisposable
        where S.Value == Output
    {
        upstream.subscribe(Sub<S>(downstream: subscriber, producer: producer))
    }

    private let producer: @MainActor (Input) -> AnyEmitter<Output>
    private let upstream: any Emitter<Input>

}
