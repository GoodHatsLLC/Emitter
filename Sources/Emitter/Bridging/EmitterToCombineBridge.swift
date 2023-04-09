#if canImport(Combine)
import Combine

extension Emitter {
  public func asCombinePublisher() -> some Publisher<Value, Failure> {
    EmitterToCombineBridge(upstream: self)
  }
}

// MARK: - EmitterCombineBridge

public struct EmitterToCombineBridge<Upstream: Emitter>: Combine.Publisher {

  // MARK: Lifecycle

  public init(
    upstream: Upstream
  ) {
    self.upstream = upstream
  }

  // MARK: Public

  public typealias Output = Upstream.Value
  public typealias Failure = Upstream.Failure

  public let upstream: Upstream

  public func receive<S>(subscriber: S) where S: Combine.Subscriber, Failure == S.Failure,
    Upstream.Value == S.Input
  {
    let subscriber = Sub(downstream: subscriber)
    let disposable = upstream.subscribe(subscriber)
    subscriber.receive(subscription: disposable)
  }

  // MARK: Internal

  struct Subscription: Combine.Subscription {
    let disposable: AutoDisposable
    let combineIdentifier = CombineIdentifier()
    func request(_: Subscribers.Demand) { }
    func cancel() {
      disposable.dispose()
    }
  }

  struct Sub<Downstream: Combine.Subscriber>: Subscriber
    where Downstream.Input == Upstream.Value, Downstream.Failure == Upstream.Failure
  {
    typealias Failure = Upstream.Failure
    typealias Value = Upstream.Value

    func receive(emission: Emission<Downstream.Input, Upstream.Failure>) {
      switch emission {
      case .value(let value):
        _ = downstream.receive(value)
      case .failed(let error):
        downstream.receive(completion: .failure(error))
      case .finished:
        downstream.receive(completion: .finished)
      }
    }

    func receive(subscription: AutoDisposable) {
      downstream.receive(subscription: Subscription(disposable: subscription))
    }

    let downstream: Downstream
  }

}
#endif
