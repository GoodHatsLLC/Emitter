import Disposable
import Emitter
import XCTest

// MARK: - CompactMapTests

final class CompactMapTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func testStream_compactMap() throws {
    let record: Unchecked<[String?]> = .init([])
    let source = PublishSubject<String?, Never>()

    source
      .compactMap { $0 }
      .subscribe { output in
        record.value.append(output)
      }
      .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    let entries: [String?] = [nil, "a", nil, nil, "d", "e"]

    for entry in entries {
      source.emit(value: entry)
    }

    XCTAssertEqual(["a", "d", "e"], record.value)
  }

  func test_dispose_releasesResources() throws {
    var record: [Int] = []
    weak var weakSourceA: PublishSubject<Int?, Never>?

    ({
      ({
        let sourceA: PublishSubject<Int?, Never> = .init()
        weakSourceA = sourceA

        sourceA
          .compactMap { $0 }
          .subscribe { value in
            record.append(value)
          }
          .stage(on: stage)

        sourceA.emit(value: 1)
        sourceA.emit(value: nil)
        sourceA.emit(value: 2)
        sourceA.emit(value: nil)
        sourceA.emit(value: 3)
      })()
      XCTAssertNotNil(weakSourceA)
      stage.dispose()
    })()
    XCTAssertNil(weakSourceA)
  }

}
