import Disposable

extension Emitter {
  public func merge<Other: Emitter>(
    _ otherB: Other
  ) -> some Emitter<Output> where Other.Output == Self.Output {
    Emitters.MergeTwo(upstreamA: erase(), upstreamB: otherB.erase())
  }
}

// MARK: - Emitters.MergeTwo

extension Emitters {
  // MARK: - Merge

  public struct MergeTwo<Upstream: Emitter>: Emitter where Upstream.Output: Sendable {

    // MARK: Lifecycle

    public init(
      upstreamA: Upstream,
      upstreamB: Upstream
    ) {
      self.upstreamA = upstreamA
      self.upstreamB = upstreamB
    }

    // MARK: Public

    public typealias Output = Upstream.Output

    public let upstreamA: Upstream
    public let upstreamB: Upstream

    public func subscribe<S: Subscriber>(
      _ subscriber: S
    )
      -> AutoDisposable
      where Output == S.Value
    {
      IntermediateSub<S>(downstream: subscriber)
        .subscribe(
          upstreamA: upstreamA,
          upstreamB: upstreamB
        )
    }

    // MARK: Private

    private final class IntermediateSub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Upstream.Output
    {

      // MARK: Lifecycle

      fileprivate init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Fileprivate

      fileprivate let downstream: Downstream

      fileprivate func subscribe(
        upstreamA: Upstream,
        upstreamB: Upstream
      )
        -> AutoDisposable
      {
        let disposableA = upstreamA.subscribe(self)
        let disposableB = upstreamB.subscribe(self)
        let disposable = AutoDisposable {
          disposableA.dispose()
          disposableB.dispose()
        }
        self.disposable = disposable
        return disposable
      }

      fileprivate func receive(emission: Emission<Upstream.Output>) {
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

      private var disposable: AutoDisposable?

    }

  }
}
