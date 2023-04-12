import Disposable

extension Emitter {
  public func merge<OtherB: Emitter, OtherC: Emitter>(
    _ otherB: OtherB,
    _ otherC: OtherC
  ) -> some Emitter<Value, Failure> where OtherB.Value == Value, OtherC.Value == Value,
    OtherB.Failure == Failure, OtherC.Failure == Failure
  {
    Emitters.MergeThree(upstreamA: self, upstreamB: otherB, upstreamC: otherC)
  }
}

// MARK: - Emitters.MergeThree

extension Emitters {
  // MARK: - Merge

  public struct MergeThree<UpstreamA: Emitter, UpstreamB: Emitter, UpstreamC: Emitter>: Emitter
    where UpstreamB.Value == UpstreamA.Value, UpstreamB.Failure == UpstreamA.Failure,
    UpstreamC.Value == UpstreamA.Value, UpstreamC.Failure == UpstreamA.Failure
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

    public typealias Value = UpstreamA.Value
    public typealias Failure = UpstreamA.Failure

    public let upstreamA: UpstreamA
    public let upstreamB: UpstreamB
    public let upstreamC: UpstreamC

    public func subscribe<S: Subscriber>(
      _ subscriber: S
    )
      -> AutoDisposable
      where S.Input == Value, S.Failure == Failure
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
      where Downstream.Input == Value, Downstream.Failure == Failure
    {

      // MARK: Lifecycle

      fileprivate init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Internal

      typealias Value = UpstreamA.Value
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

      fileprivate func receive(emission: Emission<Value, Failure>) {
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
