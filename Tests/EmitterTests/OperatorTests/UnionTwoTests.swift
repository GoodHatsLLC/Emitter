import Disposable
import Emitter
import XCTest

// MARK: - UnionTwoTests

final class UnionTwoTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  struct ErrA: Error {}
  struct ErrB: Error {}

  func test_Union2_failEnd() throws {
    let sourceA: PublishSubject<Int, ErrA> = .init()
    let sourceB: PublishSubject<String, ErrB> = .init()

    var values: [Union2<Int, String>] = []
    var errors: [Union2<ErrA, ErrB>] = []

    sourceA
      .unionInfo(sourceB)
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
        Union2<Int, String>.b("c")
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
      .unionInfo(sourceB)
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

  func test_dispose_releasesResources() throws {
    let record: Unchecked<[Tuple.Size2<Int, String>]> = .init([])
    weak var weakSourceA: PublishSubject<Int, Never>?
    weak var weakSourceB: ValueSubject<String, Never>?

    ({
      ({
        let sourceA: PublishSubject<Int, Never> = .init()
        let sourceB: ValueSubject<String, Never> = .init("Hi")
        weakSourceA = sourceA
        weakSourceB = sourceB

        sourceA
          .combineLatest(sourceB)
          .subscribe { value in
            record.value.append(value)
          }
          .stage(on: stage)

        sourceA.emit(value: 1)
        sourceA.emit(value: 2)
        sourceB.emit(value: "a")
        sourceA.emit(value: 3)
        sourceB.emit(value: "b")
        sourceB.emit(value: "c")
      })()
      XCTAssertNotNil(weakSourceA)
      XCTAssertNotNil(weakSourceB)
      stage.dispose()
    })()
    XCTAssertNil(weakSourceA)
    XCTAssertNil(weakSourceB)
  }

}
