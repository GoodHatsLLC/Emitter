import Disposable
import Emitter
import XCTest

// MARK: - ValueSubjectTests

final class ValueSubjectTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_emission() throws {
    var record: [String] = []

    let source: ValueSubject<String, Never> = .init("initial")

    source
      .subscribe { value in
        record.append(value)
      }
      .stage(on: stage)

    source.emit(value: "a")
    source.emit(value: "b")
    source.emit(value: "c")

    XCTAssertEqual(["initial", "a", "b", "c"], record)
  }

  func test_flatMapIssue() throws {
    var record: [String] = []

    let sourceA: PublishSubject<Int, Never> = .init()
    let sourceB: ValueSubject<String, Never> = .init("initial")

    sourceA
      .flatMapLatest { value in
        sourceB.map { str in
          "\(str):\(value)"
        }
      }
      .subscribe { value in
        record.append(value)
      }
      .stage(on: stage)

    sourceA.emit(value: 1)
    sourceA.emit(value: 2)
    sourceB.emit(value: "a")
    sourceB.emit(value: "b")
    sourceA.emit(value: 3)
    sourceA.emit(value: 0)
    sourceB.emit(value: "c")

    XCTAssertEqual(["initial:1", "initial:2", "a:2", "b:2", "b:3", "b:0", "c:0"], record)
  }

}
