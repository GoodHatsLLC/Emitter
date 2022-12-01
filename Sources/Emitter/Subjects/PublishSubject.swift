import Disposable
import EmitterInterface
import Foundation

// MARK: - PublishSubject

@MainActor
public final class PublishSubject<Value: Sendable>: Emitter, Source {

    public init() {}

    public typealias Output = Value

    public var id: UUID = .init()

    private var subscriptions: Set<Subscription<Value>> = []
    private var isActive = true
}

// MARK: - Source API
extension PublishSubject {
    public func emit(_ emission: Emission<Value>) {
        switch emission {
        case .finished,
             .failed:
            isActive = false
        case _:
            break
        }
        for subscription in subscriptions {
            subscription.receive(emission: emission)
        }
        if !isActive {
            subscriptions.removeAll()
        }
    }
}

// MARK: - Emitter API
extension PublishSubject {
    public func subscribe<S: Subscriber>(
        _ subscriber: S
    )
        -> AnyDisposable
        where S.Value == Value
    {
        let subscription = Subscription<Value>(
            source: self,
            subscriber: subscriber
        )
        if isActive {
            subscriptions.insert(subscription)
        } else {
            subscription.receive(emission: .finished)
            subscription.dispose()
        }
        return AnyDisposable {
            self.subscriptions.remove(subscription)?.dispose()
        }
    }
}
