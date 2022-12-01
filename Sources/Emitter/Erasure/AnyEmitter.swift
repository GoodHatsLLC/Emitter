import Disposable
import EmitterInterface

// MARK: - AnyEmitter

public struct AnyEmitter<Output: Sendable>: Emitter {

    init<E: Emitter>(_ emitter: E) where E.Output == Output {
        subscribeFunc = { emitter.subscribe($0) }
    }

    private let subscribeFunc: (any Subscriber<Output>) -> AnyDisposable

    public func subscribe<S: Subscriber>(
        _ subscriber: S
    )
        -> AnyDisposable
        where S.Value == Output {
        subscribeFunc(subscriber)
    }
}

extension AnyEmitter {
    public func erase() -> AnyEmitter<Output> { self }
}
