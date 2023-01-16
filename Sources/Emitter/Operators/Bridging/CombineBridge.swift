#if canImport(Combine)
import Combine

extension Emitter {
  var combinePublisher: some Publisher<Output, Error> {
    CombineBridge(upstream: self)
  }

  var combineDriver: some Publisher<Output, Never> {
    CombineBridge(upstream: self)
      .map { Optional($0) }
      .replaceError(with: nil)
      .compactMap { $0 }
  }
}

// MARK: - CombineBridge

public struct CombineBridge<Upstream: Emitter>: Combine.Publisher {
  public init(
    upstream: Upstream
  ) {
    self.upstream = upstream
  }

  public typealias Value = Upstream.Output

  public typealias Output = Upstream.Output
  public typealias Failure = Error

  public let upstream: Upstream

  public func receive<S>(subscriber: S) where S: Combine.Subscriber, Failure == S.Failure, Upstream.Output == S.Input {
    let subscriber = Sub(downstream: subscriber)
    let disposable = upstream.subscribe(subscriber)
    subscriber.receive(subscription: disposable)
  }

  struct Subscription: Combine.Subscription {
    let disposable: AnyDisposable
    let combineIdentifier = CombineIdentifier()
    func request(_: Subscribers.Demand) {}
    func cancel() {
      disposable.dispose()
    }
  }

  struct Sub<Downstream: Combine.Subscriber>: Subscriber
    where Downstream.Input == Output, Downstream.Failure == Error
  {
    func receive(emission: Emission<Output>) {
      switch emission {
      case .value(let value):
        _ = downstream.receive(value)
      case .failed(let error):
        downstream.receive(completion: .failure(error))
      case .finished:
        downstream.receive(completion: .finished)
      }
    }

    func receive(subscription: AnyDisposable) {
      downstream.receive(subscription: Subscription(disposable: subscription))
    }

    typealias Value = Output
    let downstream: Downstream
  }

}
#endif
