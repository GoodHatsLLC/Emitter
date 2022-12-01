import Disposable
import EmitterInterface
import Foundation

extension Emitter {
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

final class Subscribe<Value>: Subscriber {

    init(
        value: @MainActor @escaping (_ value: Value) -> Void,
        finished: @MainActor @escaping () -> Void,
        failed: @MainActor @escaping (_ error: Error) -> Void
    ) {
        handlers = .init(
            value: value,
            finished: finished,
            failed: failed
        )
    }

    struct EventHandlers {
        let value: @MainActor (_ value: Value) -> Void
        let finished: @MainActor () -> Void
        let failed: @MainActor (_ error: Error) -> Void
    }

    let id = UUID()

    @MainActor
    func receive(emission: Emission<Value>) {
        switch emission {
        case .value(let value):
            handlers.value(value)
        case .failed(let error):
            handlers.failed(error)
        case .finished:
            handlers.finished()
        }
    }

    private let handlers: EventHandlers

}
