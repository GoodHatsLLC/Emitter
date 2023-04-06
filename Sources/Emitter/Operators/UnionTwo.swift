import Disposable

extension Emitter {
  public func union<Other: Emitter>(
    _ other: Other
  ) -> some Emitter<Union2<Output, Other.Output>> {
    Emitters.UnionTwo(upstreamA: self, upstreamB: other)
  }
}

// MARK: - Emitters.UnionTwo

extension Emitters {

  public struct UnionTwo<UpstreamA: Emitter, UpstreamB: Emitter>: Emitter {

    // MARK: Lifecycle

    public init(
      upstreamA: UpstreamA,
      upstreamB: UpstreamB
    ) {
      self.upstreamA = upstreamA
      self.upstreamB = upstreamB
    }

    // MARK: Public

    public typealias Output = Union2<UpstreamA.Output, UpstreamB.Output>

    public let upstreamA: UpstreamA
    public let upstreamB: UpstreamB

    public func subscribe<S: Subscriber>(
      _ subscriber: S
    )
      -> AutoDisposable
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
        upstreamA: UpstreamA,
        upstreamB: UpstreamB
      )
        -> AutoDisposable
      {
        let disposableA = upstreamA
          .subscribe(
            Proxy(
              downstream: self,
              joinInit: Union2.a
            )
          )
        let disposableB = upstreamB
          .subscribe(
            Proxy(
              downstream: self,
              joinInit: Union2.b
            )
          )
        let disposable = AutoDisposable {
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
