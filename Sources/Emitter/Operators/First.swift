import Disposable

extension Emitter {
  public func first() -> some Emitter<Value, Failure> {
    Emitters.First(upstream: self)
  }
}

// MARK: - Emitters.First

extension Emitters {
  // MARK: - Prefix

  public struct First<Upstream: Emitter>: Emitter {

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
      where S.Value == Value, S.Failure == Failure
    {
      return upstream.subscribe(
        Sub<S>(
          downstream: subscriber
        )
      )
    }

    // MARK: Private

    private final class Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Value, Downstream.Failure == Failure
    {

      // MARK: Lifecycle

      public init(
        downstream: Downstream
      ) {
        self.downstream = downstream
      }

      // MARK: Public

      public func receive(emission: Emission<Upstream.Value, Upstream.Failure>) {
        let wasFirst = isFirst.withLock { isFirst in
          if isFirst {
            isFirst.toggle()
            return true
          } else {
            return false
          }
        }
        if wasFirst {
          switch emission {
          case .value:
            downstream.receive(emission: emission)
            downstream.receive(emission: .finished)
          default:
            downstream.receive(emission: emission)
          }
        }
      }

      // MARK: Private

      private let isFirst = Locked<Bool>(true)

      private let downstream: Downstream
    }

    private let upstream: Upstream
  }
}

// MARK: - Emitters.First + Sendable

extension Emitters.First: Sendable where Upstream: Sendable { }
