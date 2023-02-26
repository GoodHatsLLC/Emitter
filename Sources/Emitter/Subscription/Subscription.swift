import Disposable
import Disposable

// MARK: - Subscription

final class Subscription<Value: Sendable>: Sendable, Disposable, Hashable {

  init<HeadSubscriber: Subscriber>(
    subscriber: HeadSubscriber
  ) where Value == HeadSubscriber.Value {
    subscriberReceiver = { emission in subscriber.receive(emission: emission) }
    onDispose = { subscriber.receive(emission: .finished) }
  }

  init<HeadSubscriber: Subscriber>(
    subscriber: HeadSubscriber,
    onDispose: @escaping @Sendable () -> Void
  ) where Value == HeadSubscriber.Value {
    subscriberReceiver = { emission in subscriber.receive(emission: emission) }
    self.onDispose = {
      subscriber.receive(emission: .finished)
      onDispose()
    }
  }

  func dispose() {
    // TODO: Notify source?
  }

  func receive(emission: Emission<Value>) {
    subscriberReceiver(emission)
  }

  private let onDispose: @Sendable () -> Void
  private let subscriberReceiver: @Sendable (Emission<Value>) -> Void

}

extension Subscription {
  static func == (lhs: Subscription, rhs: Subscription) -> Bool {
    ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}
