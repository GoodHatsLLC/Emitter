import Disposable
import EmitterInterface

extension Emitter {
    public func subscribeValue(
        value: @escaping @MainActor (_ value: Output) -> Void
    )
        -> AnyDisposable
    {
        subscribe(
            Subscribe(
                value: value,
                finished: nil,
                failed: nil
            )
        )
    }

    public func subscribe(
        value: @escaping @MainActor (_ value: Output) -> Void,
        finished: @escaping @MainActor () -> Void = {},
        failed: @escaping @MainActor (_ error: Error) -> Void = { _ in }
    )
        -> AnyDisposable
    {
        subscribe(
            Subscribe(
                value: value,
                finished: finished,
                failed: failed
            )
        )
    }
}

// MARK: - Subscribe

private struct Subscribe<Value>: Subscriber {

    fileprivate init(
        value: @MainActor @escaping (Value) -> Void,
        finished: (@MainActor () -> Void)?,
        failed: (@MainActor (Error) -> Void)?
    ) {
        valueFunc = value
        finishedFunc = finished
        failedFunc = failed
    }

    @MainActor
    fileprivate func receive(emission: Emission<Value>) {
        switch emission {
        case .value(let value):
            valueFunc(value)
        case .failed(let error):
            failedFunc?(error)
        case .finished:
            finishedFunc?()
        }
    }

    private let valueFunc: @MainActor (Value) -> Void
    private let finishedFunc: (@MainActor () -> Void)?
    private let failedFunc: (@MainActor (Error) -> Void)?

}
