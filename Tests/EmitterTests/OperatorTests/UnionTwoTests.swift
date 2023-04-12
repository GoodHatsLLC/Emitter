import Disposable
import Emitter
import XCTest

// MARK: - UnionTwoTests

final class UnionTwoTests: XCTestCase {

  struct ErrA: Error { }
  struct ErrB: Error { }

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_Union2_failEnd() throws {
    let sourceA: PublishSubject<Int, ErrA> = .init()
    let sourceB: PublishSubject<String, ErrB> = .init()

    var values: [Union2<Int, String>] = []
    var errors: [Union2<ErrA, ErrB>] = []

    sourceA
      .unionWithTypedFailure(sourceB)
      .subscribe { value in
        values.append(value)
      } failed: { error in
        errors.append(error)
      }
      .stage(on: stage)

    sourceA.emit(value: 1)
    sourceA.emit(value: 2)
    sourceB.emit(value: "a")
    sourceA.emit(value: 3)
    sourceB.emit(value: "b")
    sourceB.emit(value: "c")
    sourceB.fail(.init())
    sourceB.emit(value: "x")
    sourceA.emit(value: 9)

    XCTAssertEqual(
      [
        Union2<Int, String>.a(1),
        Union2<Int, String>.a(2),
        Union2<Int, String>.b("a"),
        Union2<Int, String>.a(3),
        Union2<Int, String>.b("b"),
        Union2<Int, String>.b("c"),
      ],
      values
    )
  }

  func test_Union2_finishEnd() throws {
    let sourceA: PublishSubject<Int, ErrA> = .init()
    let sourceB: PublishSubject<String, ErrB> = .init()

    var values: [Union2<Int, String>] = []
    var errors: [Union2<ErrA, ErrB>] = []

    sourceA
      .unionWithTypedFailure(sourceB)
      .subscribe { value in
        values.append(value)
      } failed: { error in
        errors.append(error)
      }
      .stage(on: stage)

    sourceA.emit(value: 3)
    sourceB.emit(value: "c")
    sourceB.finish()
    sourceB.emit(value: "x")
    sourceA.emit(value: 9)
    sourceA.finish()
    sourceA.emit(value: 10)

    XCTAssertEqual(
      [
        Union2<Int, String>.a(3),
        Union2<Int, String>.b("c"),
        Union2<Int, String>.a(9),
      ],
      values
    )
  }

}
