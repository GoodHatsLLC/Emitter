import Disposable
import EmitterInterface

extension Emitter {
    public func compactMap<NewOutput: Sendable>(transformer: @escaping @MainActor (Output) -> NewOutput?)
        -> some Emitter<NewOutput>
    {
        CompactMap(upstream: self, transformer: transformer)
    }
}

// MARK: - CompactMap

@MainActor
struct CompactMap<Input: Sendable, Output: Sendable>: Emitter {

    init<Upstream: Emitter>(
        upstream: Upstream,
        transformer: @escaping @MainActor (Input) -> Output?
    ) where Upstream.Output == Input {
        self.transformer = transformer
        self.upstream = upstream
    }

    @MainActor
    struct Sub<Downstream: Subscriber>: Subscriber
        where Downstream.Value == Output
    {
        let downstream: Downstream
        let transformer: @MainActor (Input)
            -> Output?

        func receive(emission: Emission<Input>) {
            let newEmission: Emission<Output>
            switch emission {
            case .value(let value):
                guard let value = transformer(value)
                else {
                    return
                }
                newEmission = .value(value)
            case .finished:
                newEmission = .finished
            case .failed(let error):
                newEmission = .failed(error)
            }
            downstream.receive(emission: newEmission)
        }
    }

    func subscribe<S: Subscriber>(_ subscriber: S)
        -> AnyDisposable
        where S.Value == Output
    {
        upstream.subscribe(Sub<S>(downstream: subscriber, transformer: transformer))
    }

    private let transformer: @MainActor (Input) -> Output?
    private let upstream: any Emitter<Input>

}
