import Disposable

extension Emitter {
  public typealias AsyncEmitting<Value, Failure> = AsyncThrowingStream<Value, Error>

  public var values: AsyncEmitting<Value, Failure> {
    EmitterToAsyncBridge<Value, Failure>(self).values
  }
}

// MARK: - EmitterToAsyncBridge

public struct EmitterToAsyncBridge<Value, Failure> {

  public init(_ emitter: some Emitter<Value, Failure>) {
    self.values = .init { continuation in

      let disposable = emitter.subscribe(
        value: { value in
          continuation.yield(value)
        },
        finished: {
          continuation.finish()
        },
        failed: { error in
          continuation.finish(throwing: error)
        }
      )

      continuation.onTermination = { _ in
        Task {
          disposable.dispose()
        }
      }
    }
  }

  public let values: AsyncThrowingStream<Value, Error>
}
