import Disposable

// MARK: - Subscription

final class Subscription<Value: Sendable>: Sendable, Hashable {

  // MARK: Lifecycle

  init<HeadSubscriber: Subscriber>(
    subscriber: HeadSubscriber
  ) where Value == HeadSubscriber.Value {
    self.subscriberReceiver = { emission in subscriber.receive(emission: emission) }
  }

  // MARK: Internal

  func receive(emission: Emission<Value>) {
    subscriberReceiver(emission)
  }

  // MARK: Private

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
