import Disposable
import DisposableInterface
import EmitterInterface
import Foundation

// MARK: - Subscription

public final class Subscription<Value: Sendable>: Disposable, Hashable {

    public init<SourceEmitter: Source, HeadSubscriber: Subscriber>(
        source _: SourceEmitter,
        subscriber: HeadSubscriber
    ) where Value == HeadSubscriber.Value, Value == SourceEmitter.Input {
        subscriberReceiver = { emission in subscriber.receive(emission: emission) }
    }

    public func dispose() {}

    public func receive(emission: Emission<Value>) {
        subscriberReceiver(emission)
    }

    private let subscriberReceiver: (Emission<Value>) -> Void

}

extension Subscription {
    public static func == (lhs: Subscription, rhs: Subscription) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
