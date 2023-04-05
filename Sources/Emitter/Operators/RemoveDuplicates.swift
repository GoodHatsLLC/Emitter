import Disposable

extension Emitter {
  public func removeDuplicates() -> some Emitter<Output>
    where Output: Equatable
  {
    Emitters.RemoveDuplicates(upstream: self)
  }
}

// MARK: - Emitters.RemoveDuplicates

extension Emitters {
  // MARK: - RemoveDuplicates

  public struct RemoveDuplicates<Upstream: Emitter, Output: Sendable>: Emitter
    where Output: Equatable,
    Upstream.Output == Output
  {

    // MARK: Lifecycle

    public init(
      upstream: Upstream
    ) {
      self.upstream = upstream
    }

    // MARK: Public

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Value == Output, Output: Equatable
    {
      upstream.subscribe(Sub<S>(downstream: subscriber))
    }

    // MARK: Private

    private final class Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Output, Output: Equatable
    {

      // MARK: Lifecycle

      public init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Public

      public func receive(emission: Emission<Output>) {
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
      private var last: Output?

    }

    private let upstream: Upstream

  }
}
