import Disposable

extension Emitting {
  public func combineLatest<Other: Emitting>(
    _ other: Other
  ) -> some Emitting<Tuple.Size2<Output, Other.Output>> {
    Emitter.CombineLatest(upstreamA: self, upstreamB: other)
  }
}

// MARK: - Emitter.CombineLatest

extension Emitter {

  public struct CombineLatest<
    UpstreamA: Emitting & Sendable,
    UpstreamB: Emitting & Sendable
  >: Emitting,
    Sendable
    where UpstreamA.Output: Sendable, UpstreamB.Output: Sendable
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

    public typealias OutputA = UpstreamA.Output
    public typealias OutputB = UpstreamB.Output
    public typealias Output = Tuple.Size2<OutputA, OutputB>

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AnyDisposable where S.Value == Output
    {
      let stage = DisposableStage()
      let sub = Sub(downstream: subscriber)
      let mapA = Proxy(downstream: sub, joinInit: JoinSubInput.a)
      let mapB = Proxy(downstream: sub, joinInit: JoinSubInput.b)
      upstreamA
        .subscribe(mapA)
        .stage(on: stage)
      upstreamB
        .subscribe(mapB)
        .stage(on: stage)
      return stage
        .erase()
    }

    // MARK: Private

    private enum JoinSubInput {
      case a(OutputA)
      case b(OutputB)
    }

    private final class Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Output
    {

      // MARK: Lifecycle

      public init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Public

      public func receive(emission: Emission<JoinSubInput>) {
        switch emission {
        case .value(let value):
          switch value {
          case .a(let aValue):
            lastA = aValue
          case .b(let bValue):
            lastB = bValue
          }
          if let a = lastA, let b = lastB {
            downstream
              .receive(emission: .value(Tuple.create(a, b)))
          }
        case .finished:
          downstream
            .receive(emission: .finished)
        case .failed(let error):
          downstream
            .receive(emission: .failed(error))
        }
      }

      // MARK: Private

      private let downstream: Downstream

      private var lastA: OutputA?
      private var lastB: OutputB?

    }

    private struct Proxy<UpstreamValue, Downstream: Subscriber>: Subscriber
      where Downstream.Value == JoinSubInput
    {

      fileprivate init(
        downstream: Downstream,
        joinInit: @escaping (UpstreamValue) -> JoinSubInput
      ) {
        self.downstream = downstream
        self.joinInit = joinInit
      }

      fileprivate func receive(emission: Emission<UpstreamValue>) {
        let forwarded: Emission<JoinSubInput>
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
      private let joinInit: (UpstreamValue) -> JoinSubInput

    }

    private let upstreamA: UpstreamA
    private let upstreamB: UpstreamB

  }
}
