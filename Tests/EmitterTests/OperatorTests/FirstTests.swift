import Disposable
import Emitter
import XCTest

// MARK: - FirstTests

final class FirstTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_first() throws {
    var record: [String] = []
    let source = PublishSubject<String, Never>()

    source
      .first()
      .subscribe { output in
        record.append(output)
      }
      .stage(on: stage)

    XCTAssertEqual(record.count, 0)

    let entries: [String] = ["a", "d", "e"]

    for entry in entries {
      source.emit(value: entry)
    }

    XCTAssertEqual(["a"], record)
  }

}
