import Disposable

extension Emitter {
  public func union<OtherB: Emitter, OtherC: Emitter>(
    _ otherB: OtherB,
    _ otherC: OtherC
  ) -> some Emitter<Union3<Output, OtherB.Output, OtherC.Output>> {
    Emitters.UnionThree(upstreamA: self, upstreamB: otherB, upstreamC: otherC)
  }
}

// MARK: - Emitters.UnionThree

extension Emitters {

  public struct UnionThree<UpstreamA: Emitter, UpstreamB: Emitter, UpstreamC: Emitter>: Emitter {

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

    public typealias Output = Union3<UpstreamA.Output, UpstreamB.Output, UpstreamC.Output>

    public let upstreamA: UpstreamA
    public let upstreamB: UpstreamB
    public let upstreamC: UpstreamC

    public func subscribe<S: Subscriber>(
      _ subscriber: S
    )
      -> AutoDisposable
      where S.Value == Output
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
      where Downstream.Value == Output
    {

      // MARK: Lifecycle

      fileprivate init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Fileprivate

      fileprivate let downstream: Downstream

      fileprivate func subscribe(
        upstreamA: UpstreamA,
        upstreamB: UpstreamB,
        upstreamC: UpstreamC
      )
        -> AutoDisposable
      {
        let disposableA = upstreamA
          .subscribe(
            Proxy(
              downstream: self,
              joinInit: Union3.a
            )
          )
        let disposableB = upstreamB
          .subscribe(
            Proxy(
              downstream: self,
              joinInit: Union3.b
            )
          )
        let disposableC = upstreamC
          .subscribe(
            Proxy(
              downstream: self,
              joinInit: Union3.c
            )
          )
        let disposable = AutoDisposable {
          disposableA.dispose()
          disposableB.dispose()
          disposableC.dispose()
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

      private var disposable: AutoDisposable?

    }

    private struct Proxy<UpstreamValue, Downstream: Subscriber>: Subscriber
      where Downstream.Value == Output
    {

      fileprivate init(
        downstream: Downstream,
        joinInit: @escaping (UpstreamValue) -> Output
      ) {
        self.downstream = downstream
        self.joinInit = joinInit
      }

      fileprivate func receive(emission: Emission<UpstreamValue>) {
        let forwarded: Emission<Output>
        switch emission {
        case .value(let value):
          forwarded = .value(joinInit(value))
        case .finished:
          forwarded = .finished
        case .failed(let error):
          forwarded = .failed(error)
        }
        downstream.receive(emission: forwarded)
      }

      private let downstream: Downstream
      private let joinInit: (UpstreamValue) -> Output

    }

  }
}
