// MARK: - Subscriber

public protocol Subscriber<Input, Failure> {
  associatedtype Input
  associatedtype Failure: Error
  nonisolated func receive(emission: Emission<Input, Failure>)
}

extension Subscriber {
  public func eraseSubscriber() -> AnySubscriber<Input, Failure> {
    (self as? AnySubscriber<Input, Failure>) ?? .init(self)
  }
}

// MARK: - AnySubscriber

public struct AnySubscriber<Input, Failure: Error>: Subscriber, Sendable {
  public func receive(emission: Emission<Input, Failure>) {
    receiveFunc(emission)
  }

  init(_ subscriber: some Subscriber<Input, Failure>) {
    self.receiveFunc = {
      subscriber.receive(emission: $0)
    }
  }

  private let receiveFunc: @Sendable (Emission<Input, Failure>) -> Void
}
