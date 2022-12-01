import Disposable
import EmitterInterface

extension Emitter {
    public func filter(_ evaluator: @escaping @MainActor (Output) -> Bool) -> some Emitter<Output> {
        Filter(upstream: self, evaluator: evaluator)
    }
}

// MARK: - Filter

@MainActor
struct Filter<Output: Sendable>: Emitter {

    @MainActor
    init<Upstream: Emitter>(
        upstream: Upstream,
        evaluator: @escaping @MainActor (Output) -> Bool
    ) where Upstream.Output == Output {
        self.evaluator = evaluator
        self.upstream = upstream
    }

    struct Sub<Downstream: Subscriber>: Subscriber
        where Downstream.Value == Output
    {
        let downstream: Downstream
        let evaluator: @MainActor (Output)
            -> Bool

        func receive(emission: Emission<Output>) {
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
    }

    func subscribe<S: Subscriber>(_ subscriber: S)
        -> AnyDisposable
        where S.Value == Output
    {
        upstream.subscribe(Sub<S>(downstream: subscriber, evaluator: evaluator))
    }

    private let evaluator: @MainActor (Output) -> Bool
    private let upstream: any Emitter<Output>

}
