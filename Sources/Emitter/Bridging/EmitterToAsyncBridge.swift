import Disposable

extension Emitter {
  public typealias AsyncEmitting<Output> = AsyncThrowingStream<Output, Error>

  public var values: AsyncEmitting<Output> {
    EmitterToAsyncBridge<Output>(self).values
  }
}

// MARK: - EmitterToAsyncBridge

public struct EmitterToAsyncBridge<Output> {

  public init(_ emitter: some Emitter<Output>) {
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

  public let values: AsyncThrowingStream<Output, Error>
}
