import Disposable
import Emitter
import XCTest

// MARK: - Merge3Tests

final class Merge3Tests: XCTestCase {

  struct MergeFail: Error { }

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_merge() throws {
    var record: [Int] = []
    let sourceA: PublishSubject<Int, Never> = .init()
    let sourceB: PublishSubject<Int, Never> = .init()
    let sourceC: PublishSubject<Int, Never> = .init()

    sourceA
      .merge(sourceB, sourceC)
      .subscribe { value in
        record.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.count, 0)

    sourceA.emit(value: 1)
    sourceB.emit(value: -1)
    sourceC.emit(value: 99)
    sourceA.emit(value: 2)
    sourceB.emit(value: -2)

    XCTAssertEqual([1, -1, 99, 2, -2], record)
  }

  func test_merge_finish() throws {
    var record: [Int] = []
    let sourceA: PublishSubject<Int, Never> = .init()
    let sourceB: PublishSubject<Int, Never> = .init()
    let sourceC: PublishSubject<Int, Never> = .init()

    sourceA
      .merge(sourceB, sourceC)
      .subscribe { value in
        record.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.count, 0)

    sourceA.emit(value: 2)
    sourceB.emit(value: -2)
    sourceC.emit(value: 99)
    sourceA.finish()
    sourceA.emit(value: 3)
    sourceB.emit(value: -3)
    sourceC.emit(value: 33)
    sourceB.finish()
    sourceC.finish()
    sourceA.emit(value: 123)
    sourceB.emit(value: 123)
    sourceC.emit(value: 123)

    XCTAssertEqual([2, -2, 99, -3, 33], record)
  }

  func test_merge_fail() throws {
    var record: [Int] = []
    let sourceA: PublishSubject<Int, MergeFail> = .init()
    let sourceB: PublishSubject<Int, MergeFail> = .init()
    let sourceC: PublishSubject<Int, MergeFail> = .init()

    sourceA
      .merge(sourceB, sourceC)
      .subscribe { value in
        record.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.count, 0)

    sourceA.emit(value: 2)
    sourceB.emit(value: -2)
    sourceC.emit(value: 22)
    sourceA.fail(MergeFail())
    sourceA.emit(value: 3)
    sourceB.emit(value: -3)
    sourceC.emit(value: 33)

    XCTAssertEqual([2, -2, 22], record)
  }

}
