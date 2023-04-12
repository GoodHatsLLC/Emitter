import Disposable
import Emitter
import XCTest

// MARK: - UnionThreeTests

final class UnionThreeTests: XCTestCase {

  struct ErrA: Error, Equatable { }
  struct ErrB: Error, Equatable { }
  struct ErrC: Error, Equatable { }

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_Union3_failEnd() throws {
    let sourceA: PublishSubject<Int, ErrA> = .init()
    let sourceB: PublishSubject<String, ErrB> = .init()
    let sourceC: PublishSubject<Bool, ErrC> = .init()

    var values: [Union3<Int, String, Bool>] = []
    var errors: [Union3<ErrA, ErrB, ErrC>] = []
    var finishCount = 0

    sourceA
      .unionWithTypedFailure(sourceB, sourceC)
      .subscribe { value in
        values.append(value)
      } finished: {
        finishCount += 1
      } failed: { error in
        errors.append(error)
      }
      .stage(on: stage)

    sourceA.emit(value: 1)
    sourceB.emit(value: "1")
    sourceC.emit(value: true)
    sourceC.fail(.init())
    sourceB.fail(.init())
    sourceA.finish()
    sourceA.emit(value: 0)
    sourceB.emit(value: "O")
    sourceC.emit(value: false)

    XCTAssertEqual(
      [
        Union3<Int, String, Bool>.a(1),
        Union3<Int, String, Bool>.b("1"),
        Union3<Int, String, Bool>.c(true),
      ],
      values
    )
    XCTAssertEqual(
      [
        Union3<ErrA, ErrB, ErrC>.c(.init()),
      ],
      errors
    )
    XCTAssertEqual(finishCount, 0)
  }

  func test_Union3_finishEnd() throws {
    let sourceA: PublishSubject<Int, ErrA> = .init()
    let sourceB: PublishSubject<String, ErrB> = .init()
    let sourceC: PublishSubject<Bool, ErrC> = .init()

    var values: [Union3<Int, String, Bool>] = []
    var errors: [Union3<ErrA, ErrB, ErrC>] = []
    var finishCount = 0

    sourceA
      .unionWithTypedFailure(sourceB, sourceC)
      .subscribe { value in
        values.append(value)
      } finished: {
        finishCount += 1
      } failed: { error in
        errors.append(error)
      }
      .stage(on: stage)

    sourceA.emit(value: 1)
    sourceA.finish()
    sourceA.emit(value: 1)

    sourceB.emit(value: "1")
    sourceB.emit(value: "1")
    sourceB.finish()
    sourceB.emit(value: "1")

    sourceC.emit(value: true)
    sourceC.emit(value: true)
    sourceC.emit(value: true)
    sourceC.finish()
    sourceC.emit(value: true)

    sourceA.fail(.init())
    sourceB.fail(.init())
    sourceC.fail(.init())

    sourceA.emit(value: 0)
    sourceB.emit(value: "O")
    sourceC.emit(value: false)

    XCTAssertEqual(
      [
        Union3<Int, String, Bool>.a(1),
        Union3<Int, String, Bool>.b("1"),
        Union3<Int, String, Bool>.b("1"),
        Union3<Int, String, Bool>.c(true),
        Union3<Int, String, Bool>.c(true),
        Union3<Int, String, Bool>.c(true),
      ],
      values
    )
    XCTAssertEqual(
      [],
      errors
    )
    XCTAssertEqual(finishCount, 1)
  }

}
