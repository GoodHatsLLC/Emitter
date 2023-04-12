import Disposable

// MARK: - Subscription

final class Subscription<Output, Failure: Error>: Sendable, Hashable {

  // MARK: Lifecycle

  init<Sub: Subscriber>(
    subscriber: Sub
  ) where Output == Sub.Input, Failure == Sub.Failure {
    self.subscriberReceiver = { emission in subscriber.receive(emission: emission) }
  }

  // MARK: Internal

  func receive(emission: Emission<Output, Failure>) {
    subscriberReceiver(emission)
  }

  // MARK: Private

  private let subscriberReceiver: @Sendable (Emission<Output, Failure>) -> Void

}

extension Subscription {
  static func == (lhs: Subscription, rhs: Subscription) -> Bool {
    ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}
