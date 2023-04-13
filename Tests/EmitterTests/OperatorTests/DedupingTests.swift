import Disposable
import Emitter
import XCTest

// MARK: - DedupingTests

final class DedupingTests: XCTestCase {

  class CharObj {

    // MARK: Lifecycle

    init(_ char: String) {
      self.char = char
    }

    // MARK: Internal

    let char: String
  }

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func testStream_dedupe_equatable() {
    let record: Unchecked<[String]> = .init([])
    let source = PublishSubject<String, Never>()

    source
      .dedupe()
      .subscribe { output in
        record.value.append(output)
      }
      .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    let entries: [String] = ["a", "a", "d", "e", "e"]

    for entry in entries {
      source.emit(value: entry)
    }

    XCTAssertEqual(["a", "d", "e"], record.value)
  }

  func testStream_dedupe_byFilter() {
    let record: Unchecked<[String]> = .init([])
    let source = PublishSubject<String, Never>()

    source
      .dedupe(by: { $0.lowercased() == $1.lowercased() })
      .subscribe { output in
        record.value.append(output)
      }
      .stage(on: stage)

    let entries: [String] = ["a", "A", "D", "d", "ƀ", "b", "🫵", "B", "😀"]

    for entry in entries {
      source.emit(value: entry)
    }

    XCTAssertEqual(["a", "D", "ƀ", "b", "🫵", "B", "😀"], record.value)
  }

  func testStream_dedupe_nonEquatable() {
    let record: Unchecked<[String]> = .init([])
    let source = PublishSubject<CharObj, Never>()

    source
      .dedupe(by: { $0.char == $1.char })
      .map(\.char)
      .subscribe { output in
        record.value.append(output)
      }
      .stage(on: stage)

    let entries = ["a", "a", "d", "d", "1", "2", "3"]
      .map { CharObj($0) }

    XCTAssertNil(entries.first as? any Equatable)

    for entry in entries {
      source.emit(value: entry)
    }

    XCTAssertEqual(["a", "d", "1", "2", "3"], record.value)
  }

  func test_dispose_releasesResources() throws {
    let record: Unchecked<[Int]> = .init([])
    weak var weakSourceA: PublishSubject<Int, Never>?

    ({
      ({
        let sourceA: PublishSubject<Int, Never> = .init()
        weakSourceA = sourceA

        sourceA
          .dedupe()
          .subscribe { value in
            record.value.append(value)
          }
          .stage(on: stage)

        sourceA.emit(value: 1)
        sourceA.emit(value: 2)
        sourceA.emit(value: 2)
        sourceA.emit(value: 3)
        sourceA.emit(value: 3)
        sourceA.emit(value: 1)
      })()
      XCTAssertNotNil(weakSourceA)
      stage.dispose()
    })()
    XCTAssertNil(weakSourceA)
    XCTAssertEqual([1, 2, 3, 1], record.value)
  }

}
