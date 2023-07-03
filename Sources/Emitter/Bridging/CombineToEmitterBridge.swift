
#if canImport(Combine)
import class Combine.AnyCancellable
import struct Combine.AnyPublisher
import protocol Combine.Cancellable
import struct Combine.CombineIdentifier
import protocol Combine.Publisher
import protocol Combine.Subject
import protocol Combine.Subscriber
import enum Combine.Subscribers
import protocol Combine.Subscription
import Disposable

extension Emitters {
  public static func bridge<Publisher: Combine.Publisher>(_ publisher: Publisher)
    -> some Emitter<Publisher.Output, Publisher.Failure>
  {
    CombineToEmitterBridge(upstream: publisher)
  }
}

public struct CombineToEmitterBridge<Upstream: Combine.Publisher>: Emitter, @unchecked Sendable {

  // MARK: Lifecycle

  public init(
    upstream: Upstream
  ) {
    self.upstream = upstream
  }

  // MARK: Public

  public typealias Output = Upstream.Output
  public typealias Failure = Upstream.Failure

  public let upstream: Upstream

  public func subscribe<S: Subscriber>(_ subscriber: S) -> AutoDisposable
    where Upstream.Output == S.Input, Upstream.Failure == S.Failure
  {
    let subscriber = Sub<S, Upstream.Failure>(downstream: subscriber)
    upstream.receive(subscriber: subscriber)
    return subscriber.auto()
  }

  // MARK: Private

  private final class Sub<Downstream: Subscriber, Failure: Error>: Combine.Subscriber, Disposable
    where Downstream.Input == Output, Downstream.Failure == Failure
  {

    // MARK: Lifecycle

    init(downstream: Downstream) {
      self.downstream = downstream
    }

    // MARK: Internal

    typealias Input = Downstream.Input

    let combineIdentifier = CombineIdentifier()

    let downstream: Downstream
    var subscription: AutoDisposable?
    var hasStarted: Bool = false

    var isDisposed: Bool {
      subscription?.isDisposed ?? !hasStarted
    }

    func receive(_ input: Downstream.Input) -> Subscribers.Demand {
      hasStarted = true
      downstream.receive(emission: .value(input))
      return .unlimited
    }

    func receive(completion: Subscribers.Completion<Failure>) {
      switch completion {
      case .finished:
        downstream.receive(emission: .finished)
      case .failure(let failure):
        downstream.receive(emission: .failed(failure))
      }
    }

    func receive(subscription: any Combine.Subscription) {
      subscription.request(.unlimited)
      self.subscription = ErasedDisposable(subscription).auto()
    }

    func dispose() {
      subscription?.dispose()
    }

  }

}
#endif
