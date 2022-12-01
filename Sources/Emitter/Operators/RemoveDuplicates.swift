import Disposable
import EmitterInterface

extension Emitter {
    public func removeDuplicates() -> some Emitter<Output>
        where Output: Equatable
    {
        RemoveDuplicates(upstream: self)
    }
}

// MARK: - RemoveDuplicates

@MainActor
struct RemoveDuplicates<Output: Sendable>: Emitter where Output: Equatable {

    init<Upstream: Emitter>(
        upstream: Upstream
    ) where Upstream.Output == Output {
        self.upstream = upstream
    }

    @MainActor
    final class Sub<Downstream: Subscriber>: Subscriber
        where Downstream.Value == Output, Output: Equatable
    {

        init(downstream: Downstream) {
            self.downstream = downstream
        }

        let downstream: Downstream
        var last: Output? = nil

        func receive(emission: Emission<Output>) {
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
    }

    @usableFromInline
    func subscribe<S: Subscriber>(_ subscriber: S)
        -> AnyDisposable
        where S.Value == Output, Output: Equatable
    {
        upstream.subscribe(Sub<S>(downstream: subscriber))
    }

    private let upstream: any Emitter<Output>

}
