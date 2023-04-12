import Disposable

extension Emitter {
  public func merge<OtherB: Emitter, OtherC: Emitter>(
    _ otherB: OtherB,
    _ otherC: OtherC
  ) -> some Emitter<Output, Failure> where OtherB.Output == Output, OtherC.Output == Output,
    OtherB.Failure == Failure, OtherC.Failure == Failure
  {
    Emitters.MergeThree(upstreamA: self, upstreamB: otherB, upstreamC: otherC)
  }
}

// MARK: - Emitters.MergeThree

extension Emitters {
  // MARK: - Merge

  public struct MergeThree<UpstreamA: Emitter, UpstreamB: Emitter, UpstreamC: Emitter>: Emitter
    where UpstreamB.Output == UpstreamA.Output, UpstreamB.Failure == UpstreamA.Failure,
    UpstreamC.Output == UpstreamA.Output, UpstreamC.Failure == UpstreamA.Failure
  {

    // MARK: Lifecycle

    public init(
      upstreamA: UpstreamA,
      upstreamB: UpstreamB,
      upstreamC: UpstreamC
    ) {
      self.upstreamA = upstreamA
      self.upstreamB = upstreamB
      self.upstreamC = upstreamC
    }

    // MARK: Public

    public typealias Output = UpstreamA.Output
    public typealias Failure = UpstreamA.Failure

    public let upstreamA: UpstreamA
    public let upstreamB: UpstreamB
    public let upstreamC: UpstreamC

    public func subscribe<S: Subscriber>(
      _ subscriber: S
    )
      -> AutoDisposable
      where S.Input == Output, S.Failure == Failure
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
      where Downstream.Input == Output, Downstream.Failure == Failure
    {

      // MARK: Lifecycle

      fileprivate init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Internal

      typealias Output = UpstreamA.Output
      typealias Failure = UpstreamA.Failure

      // MARK: Fileprivate

      fileprivate let downstream: Downstream

      fileprivate func subscribe(
        upstreamA: UpstreamA,
        upstreamB: UpstreamB,
        upstreamC: UpstreamC
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

      fileprivate func receive(emission: Emission<Output, Failure>) {
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

// MARK: - Emitters.MergeThree + Sendable

extension Emitters.MergeThree: Sendable where UpstreamA: Sendable, UpstreamB: Sendable,
  UpstreamC: Sendable { }
