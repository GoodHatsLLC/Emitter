import Disposable
import Emitter
import XCTest

// MARK: - SharedTests

final class SharedTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  @available(macOS 13.0, *)
  func test_shared() throws {
    var record1: [String] = []
    var record2: [String] = []
    var record3: [String] = []
    let source = PublishSubject<String, Never>()

    let shared = source
      .shared(replay: 5)

    shared.subscribe { value in
      record1.append(value)
    }.stage(on: stage)

    XCTAssertEqual(record1.count, 0)

    let entries: [String] = ["a", "d", "e", "f", "g", "h", "i"]

    for entry in entries {
      source.emit(value: entry)
    }

    XCTAssertEqual(record1.count, 7)

    shared.subscribe { value in
      record2.append(value)
    }.stage(on: stage)

    XCTAssertEqual(record2, ["e", "f", "g", "h", "i"])

    stage.reset()

    shared.subscribe { value in
      record3.append(value)
    }.stage(on: stage)

    XCTAssertEqual(record3, [])

    let entries2: [String] = ["a", "b", "x"]

    for entry in entries2 {
      source.emit(value: entry)
    }

    XCTAssertEqual(record3, entries2)
  }

}
