import Disposable
import Emitter
import XCTest

// MARK: - AsyncStreamTests

final class AsyncStreamTests: XCTestCase {

  var source: PublishSubject<String>!
  var stage: DisposableStage!

  override func setUp() {
    source = .init()
    stage = .init()
  }

  override func tearDown() async throws {
    source = nil
    stage.dispose()
    stage = nil
  }

  func testStream_publishesInOrder_toAsyncIteration() async throws {
    let handle = Task {
      var record: [String] = []
      for try await value in source.values {
        record.append(value)
      }
      return record
    }

    let entries = ["a", "b", "c", "d", "e"]

    _ = await Task {
      for entry in entries {
        source.emit(.value(entry))
      }
    }.result

    await attemptTaskFlushHack()

    // cancel task to finish
    handle.cancel()
    let record = try await handle.value

    XCTAssertEqual(entries, record)
  }

  func testStream_finishes_asyncIteration() async throws {
    let handle = Task {
      var record: [String] = []
      for try await value in source.values {
        record.append(value)
      }
      return record
    }

    await attemptTaskFlushHack(count: 1)

    let entries = ["a", "b", "c"]

    _ = await Task {
      for entry in entries {
        source.emit(.value(entry))
      }
      // source finishes
      source.emit(.finished)
    }.result

    let record = try await handle.value

    XCTAssertEqual(entries, record)
  }

}

// MARK: AsyncStreamTests.Failure

extension AsyncStreamTests {
  enum Failure: Error {
    case sourceFail
  }
}

private func attemptTaskFlushHack(count: Int = 25) async {
  for _ in 0..<count {
    _ = await Task { try await Task.sleep(nanoseconds: 1 * USEC_PER_SEC) }.result
  }
}
