import Disposable

extension Emitter {
  public func removeDuplicates() -> some Emitter<Value, Failure>
    where Value: Equatable
  {
    Emitters.RemoveDuplicates(upstream: self)
  }
}

// MARK: - Emitters.RemoveDuplicates

extension Emitters {
  // MARK: - RemoveDuplicates

  public struct RemoveDuplicates<Upstream: Emitter>: Emitter
    where Upstream.Value: Equatable
  {

    // MARK: Lifecycle

    public init(
      upstream: Upstream
    ) {
      self.upstream = upstream
    }

    // MARK: Public

    public typealias Value = Upstream.Value
    public typealias Failure = Upstream.Failure

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Input == Value, S.Failure == Failure
    {
      upstream.subscribe(Sub<S>(downstream: subscriber))
    }

    // MARK: Private

    private final class Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Input == Upstream.Value, Downstream.Failure == Upstream.Failure
    {

      // MARK: Lifecycle

      public init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Public

      public func receive(emission: Emission<Value, Failure>) {
        switch emission {
        case .value(let value):
          if value != last {
            last = value
            downstream.receive(emission: emission)
          }
        case _:
          downstream.receive(emission: emission)
        }
      }

      // MARK: Private

      private let downstream: Downstream
      private var last: Value?

    }

    private let upstream: Upstream

  }
}
