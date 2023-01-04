import Disposable
import DisposableInterface
import EmitterInterface

// MARK: - Subscription

final class Subscription<Value: Sendable>: Disposable, Hashable {

  init<SourceEmitter: Source, HeadSubscriber: Subscriber>(
    source _: SourceEmitter,
    subscriber: HeadSubscriber
  ) where Value == HeadSubscriber.Value, Value == SourceEmitter.Input {
    subscriberReceiver = { emission in subscriber.receive(emission: emission) }
  }

  func dispose() {}

  func receive(emission: Emission<Value>) {
    subscriberReceiver(emission)
  }

  private let subscriberReceiver: (Emission<Value>) -> Void

}

extension Subscription {
  static func == (lhs: Subscription, rhs: Subscription) -> Bool {
    ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}
