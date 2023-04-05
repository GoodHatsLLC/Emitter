import Disposable

extension Emitter {
  public func union<Other: Emitter>(
    _ other: Other
  ) -> some Emitter<UnionType.Of2<Output, Other.Output>>
    where Other.Output: UnionType.Unionable, Output: UnionType.Unionable
  {
    Emitters.Union(upstreamA: self, upstreamB: other)
  }
}

// MARK: - Emitters.Union

extension Emitters {

  public struct Union<UpstreamA: Emitter, UpstreamB: Emitter>: Emitter
    where UpstreamA.Output: UnionType.Unionable, UpstreamB.Output: UnionType.Unionable
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

    public typealias Output = UnionType.Of2<UpstreamA.Output, UpstreamB.Output>

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
              joinInit: UnionType.Of2.a
            )
          )
        let disposableB = upstreamB
          .subscribe(
            Proxy(
              downstream: self,
              joinInit: UnionType.Of2.b
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
