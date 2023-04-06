import Disposable
import Emitter
import XCTest

// MARK: - EmitterToAsyncTests

final class EmitterToAsyncTests: XCTestCase {

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
        source.emit(value: entry)
      }
    }.result

    await Flush.tasks()

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
        source.emit(value: entry)
      }
      // source finishes
      source.finish()
    }.result

    let record = try await handle.value

    XCTAssertEqual(entries, record)
  }

}

// MARK: EmitterToAsyncTests.Failure

extension EmitterToAsyncTests {
  enum Failure: Error {
    case sourceFail
  }
}
