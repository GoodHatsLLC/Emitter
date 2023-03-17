import Disposable

extension Emitting {
  public func merge<Other: Emitting>(
    _ other: Other
  ) -> some Emitting<Output> where Other.Output == Output {
    Emitter.Merge(upstreamA: self, upstreamB: other)
  }
}

// MARK: - Emitter.Merge

extension Emitter {
  // MARK: - Merge

  public struct Merge<UpstreamA: Emitting, UpstreamB: Emitting, Output: Sendable>: Emitting
    where UpstreamA.Output == Output, UpstreamB.Output == Output
  {

    // MARK: Lifecycle

    public init(
      upstreamA: UpstreamA,
      upstreamB: UpstreamB
    ) {
      self.upstreamA = upstreamA
      self.upstreamB = upstreamB
    }

    // MARK: Public

    public let upstreamA: UpstreamA
    public let upstreamB: UpstreamB

    public func subscribe<S: Subscriber>(
      _ subscriber: S
    )
      -> AnyDisposable
      where S.Value == Output
    {
      IntermediateSub<S>(downstream: subscriber)
        .subscribe(
          upstreamA: upstreamA,
          upstreamB: upstreamB
        )
    }

    // MARK: Private

    private final class IntermediateSub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Output
    {

      // MARK: Lifecycle

      fileprivate init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Fileprivate

      fileprivate let downstream: Downstream

      fileprivate func subscribe(
        upstreamA: some Emitting<Output>,
        upstreamB: some Emitting<Output>
      )
        -> AnyDisposable
      {
        let disposableA = upstreamA.subscribe(self)
        let disposableB = upstreamB.subscribe(self)
        let disposable = AnyDisposable {
          disposableA.dispose()
          disposableB.dispose()
        }
        self.disposable = disposable
        return disposable
      }

      fileprivate func receive(emission: Emission<Output>) {
        downstream.receive(emission: emission)

        switch emission {
        case .value: break
        case .failed,
             .finished:
          if let disposable {
            disposable.dispose()
          }
        }
      }

      // MARK: Private

      private var disposable: AnyDisposable?

    }

  }
}
