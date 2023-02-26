import Disposable
import Emitter
import XCTest

// MARK: - AsyncStreamTests

final class AsyncStreamTests: XCTestCase {

  var source: PublishSubject<String> = .init()
  let stage = DisposableStage()

  override func setUp() {
    source = .init()
  }

  override func tearDown() async throws {
    source = .init()
    stage.reset()
  }

  func testStream_publishesInOrder_toAsyncIteration() async throws {
    let handle = Task { [values = source.values] in
      var record: [String] = []
      for try await value in values {
        record.append(value)
      }
      return record
    }

    let entries = ["a", "b", "c", "d", "e"]

    _ = await Task { [source] in
      for entry in entries {
        source.emit(.value(entry))
      }
    }.result

    await Task.flushHack()

    // cancel task to finish
    handle.cancel()
    let record = try await handle.value

    XCTAssertEqual(entries, record)
  }

  func testStream_finishes_asyncIteration() async throws {
    let handle = Task { [values = source.values] in
      var record: [String] = []
      for try await value in values {
        record.append(value)
      }
      return record
    }

    let entries = ["a", "b", "c"]

    _ = await Task { [source] in
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
