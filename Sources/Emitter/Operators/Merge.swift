import Disposable
import EmitterInterface

extension Emitter {
    public func merge<Other: Emitter>(_ other: Other) -> some Emitter<Output>
        where Other.Output == Output
    {
        Merge(upstreamA: self, upstreamB: other)
    }
}

// MARK: - Merge

@MainActor
struct Merge<Output: Sendable>: Emitter {

    init<UpstreamA: Emitter, UpstreamB: Emitter>(
        upstreamA: UpstreamA,
        upstreamB: UpstreamB
    ) where UpstreamA.Output == Output, UpstreamB.Output == Output {
        self.upstreamA = upstreamA
        self.upstreamB = upstreamB
    }

    @MainActor
    struct IntermediateSub<Downstream: Subscriber>: Subscriber
        where Downstream.Value == Output
    {
        let downstream: Downstream
        weak var disposable: AnyDisposable?

        mutating func subscribe(
            upstreamA: any Emitter<Output>,
            upstreamB: any Emitter<Output>
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

        func receive(emission: Emission<Output>) {
            downstream.receive(emission: emission)

            // Clean up the non-emitting upstream for failure.
            // TODO: Research cleanup implementation
            switch emission {
            case .value: break
            case .finished,
                 .failed:
                if let disposable {
                    disposable.dispose()
                }
            }
        }
    }

    func subscribe<S: Subscriber>(_ subscriber: S)
        -> AnyDisposable
        where S.Value == Output
    {
        var sub = IntermediateSub<S>(downstream: subscriber)
        return sub.subscribe(
            upstreamA: upstreamA,
            upstreamB: upstreamB
        )
    }

    private let upstreamA: any Emitter<Output>
    private let upstreamB: any Emitter<Output>

}
