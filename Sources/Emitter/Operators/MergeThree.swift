import Disposable

extension Emitter {
  public func merge<OtherA: Emitter, OtherB: Emitter>(
    _ otherB: Self,
    _ otherC: Self
  ) -> some Emitter<Output> where OtherA.Output == Self.Output, OtherB.Output == Self.Output {
    Emitters.MergeThree(upstreamA: erase(), upstreamB: otherB.erase(), upstreamC: otherC.erase())
  }
}

// MARK: - Emitters.MergeThree

extension Emitters {
  // MARK: - Merge

  public struct MergeThree<Upstream: Emitter>: Emitter where Upstream.Output: Sendable {

    // MARK: Lifecycle

    public init(
      upstreamA: Upstream,
      upstreamB: Upstream,
      upstreamC: Upstream
    ) {
      self.upstreamA = upstreamA
      self.upstreamB = upstreamB
      self.upstreamC = upstreamC
    }

    // MARK: Public

    public typealias Output = Upstream.Output

    public let upstreamA: Upstream
    public let upstreamB: Upstream
    public let upstreamC: Upstream

    public func subscribe<S: Subscriber>(
      _ subscriber: S
    )
      -> AutoDisposable
      where Output == S.Value
    {
      IntermediateSub<S>(downstream: subscriber)
        .subscribe(
          upstreamA: upstreamA,
          upstreamB: upstreamB,
          upstreamC: upstreamC
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
        upstreamB: Upstream,
        upstreamC: Upstream
      )
        -> AutoDisposable
      {
        let disposableA = upstreamA.subscribe(self)
        let disposableB = upstreamB.subscribe(self)
        let disposableC = upstreamC.subscribe(self)
        let disposable = AutoDisposable {
          disposableA.dispose()
          disposableB.dispose()
          disposableC.dispose()
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
