import Disposable

extension Emitter {
  public func first() -> some Emitter<Output> {
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

    public typealias Output = Upstream.Output

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Value == Output
    {
      return upstream.subscribe(
        Sub<S>(
          downstream: subscriber
        )
      )
    }

    // MARK: Private

    private final class Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Output
    {

      // MARK: Lifecycle

      public init(
        downstream: Downstream
      ) {
        self.downstream = downstream
      }

      // MARK: Public

      public func receive(emission: Emission<Upstream.Output>) {
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
