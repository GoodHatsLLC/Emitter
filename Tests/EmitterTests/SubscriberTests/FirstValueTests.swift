import Disposable
import Emitter
import XCTest

// MARK: - FirstValueTests

final class FirstValueTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_firstValue() async throws {
    let source = PublishSubject<String, Never>()
    Task {
      await Flush.tasks()
      let entries: [String] = ["a", "d", "e"]
      for entry in entries {
        source.emit(value: entry)
      }
    }
    let first = await source.firstValue
    XCTAssertEqual(first, "a")
  }

}
