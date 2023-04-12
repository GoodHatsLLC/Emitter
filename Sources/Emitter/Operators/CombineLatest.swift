import Disposable

extension Emitter {
  public func combineLatest<Other: Emitter>(
    _ other: Other
  ) -> some Emitter<Tuple.Size2<Value, Other.Value>, Failure> where Other.Failure == Failure {
    Emitters.CombineLatest(upstreamA: self, upstreamB: other)
  }
}

// MARK: - Emitters.CombineLatest

extension Emitters {

  public struct CombineLatest<
    UpstreamA: Emitter & Sendable,
    UpstreamB: Emitter & Sendable,
    Failure: Error
  >: Emitter,
    Sendable
    where UpstreamA.Failure == Failure,
    UpstreamB.Failure == Failure
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

    public typealias ValueA = UpstreamA.Value
    public typealias ValueB = UpstreamB.Value
    public typealias Value = Tuple.Size2<ValueA, ValueB>

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable where S.Input == Value, S.Failure == Failure
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
        .auto()
    }

    // MARK: Private

    private enum JoinSubInput {
      case a(ValueA)
      case b(ValueB)
    }

    private final class Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Input == Value, Downstream.Failure == Failure
    {

      // MARK: Lifecycle

      public init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Public

      public func receive(emission: Emission<JoinSubInput, Failure>) {
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

      private var lastA: ValueA?
      private var lastB: ValueB?

    }

    private struct Proxy<UpstreamValue, Downstream: Subscriber>: Subscriber
      where Downstream.Input == JoinSubInput, Downstream.Failure == Failure
    {

      fileprivate init(
        downstream: Downstream,
        joinInit: @escaping (UpstreamValue) -> JoinSubInput
      ) {
        self.downstream = downstream
        self.joinInit = joinInit
      }

      fileprivate func receive(emission: Emission<UpstreamValue, Failure>) {
        let forwarded: Emission<JoinSubInput, Failure>
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
