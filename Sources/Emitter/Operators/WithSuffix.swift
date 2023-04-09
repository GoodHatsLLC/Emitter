import Disposable

extension Emitter {
  public func withSuffix(_ prefix: Value...) -> some Emitter<Value, Failure> {
    Emitters.WithSuffix(upstream: self, suffixValues: prefix)
  }

  public func withSuffix(_ prefix: [Value]) -> some Emitter<Value, Failure> {
    Emitters.WithSuffix(upstream: self, suffixValues: prefix)
  }
}

// MARK: - Emitters.WithSuffix

extension Emitters {
  // MARK: - Prefix

  public struct WithSuffix<Upstream: Emitter>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      suffixValues: [Value]
    ) {
      self.upstream = upstream
      self.suffixValues = suffixValues
    }

    // MARK: Public

    public typealias Value = Upstream.Value
    public typealias Failure = Upstream.Failure

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Value == Value, S.Failure == Failure
    {
      return upstream.subscribe(
        Sub<S>(
          downstream: subscriber,
          suffixValues: suffixValues
        )
      )
    }

    // MARK: Private

    private final class Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Value, Downstream.Failure == Failure
    {

      // MARK: Lifecycle

      public init(
        downstream: Downstream,
        suffixValues: [Value]
      ) {
        self.downstream = downstream
        self.suffixValues = suffixValues
      }

      // MARK: Public

      public func receive(emission: Emission<Upstream.Value, Upstream.Failure>) {
        switch emission {
        case .value:
          downstream.receive(emission: emission)
        case .finished:
          for value in suffixValues {
            downstream.receive(emission: .value(value))
          }
          downstream.receive(emission: .finished)
        case .failed:
          downstream.receive(emission: emission)
        }
      }

      // MARK: Private

      private let downstream: Downstream
      private let suffixValues: [Value]
    }

    private let upstream: Upstream
    private let suffixValues: [Value]
  }
}
