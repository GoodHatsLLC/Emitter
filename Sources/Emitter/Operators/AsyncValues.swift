import Disposable
import EmitterInterface

extension Emitter {
  public var values: AsyncThrowingStream<Output, Error> {
    .init { continuation in

      let disposable = subscribe(
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
}
