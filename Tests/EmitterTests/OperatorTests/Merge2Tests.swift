import Disposable
import Emitter
import XCTest

// MARK: - Merge2Tests

final class Merge2Tests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func testStream_merge() throws {
    var record: [Int] = []
    let sourceA: PublishSubject<Int, Never> = .init()
    let sourceB: PublishSubject<Int, Never> = .init()

    sourceA
      .merge(sourceB)
      .subscribe { value in
        record.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.count, 0)

    sourceA.emit(value: 1)
    sourceB.emit(value: -1)
    sourceA.emit(value: 2)
    sourceB.emit(value: -2)
    sourceA.emit(value: 3)
    sourceB.emit(value: -3)

    XCTAssertEqual([1, -1, 2, -2, 3, -3], record)
  }

  func testStream_merge_finish() throws {
    var record: [Int] = []
    let sourceA: PublishSubject<Int, Never> = .init()
    let sourceB: PublishSubject<Int, Never> = .init()

    sourceA
      .merge(sourceB)
      .subscribe { value in
        record.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.count, 0)

    sourceA.emit(value: 2)
    sourceB.emit(value: -2)
    sourceA.finish()
    sourceA.emit(value: 3)
    sourceB.emit(value: -3)
    sourceB.finish()
    sourceB.emit(value: -3)

    XCTAssertEqual([2, -2, -3], record)
  }

  struct MergeFail: Error {}

  func testStream_merge_fail() throws {
    var record: [Int] = []
    let sourceA: PublishSubject<Int, MergeFail> = .init()
    let sourceB: PublishSubject<Int, MergeFail> = .init()

    sourceA
      .merge(sourceB)
      .subscribe { value in
        record.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.count, 0)

    sourceA.emit(value: 2)
    sourceB.emit(value: -2)
    sourceA.fail(MergeFail())
    sourceA.emit(value: 3)
    sourceB.emit(value: -3)

    XCTAssertEqual([2, -2], record)
  }

}
