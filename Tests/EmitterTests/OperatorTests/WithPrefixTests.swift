import Disposable
import Emitter
import XCTest

// MARK: - WithPrefixTests

final class WithPrefixTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_prefix() throws {
    let record: Unchecked<[String]> = .init([])
    let source = PublishSubject<String>()
    let prefixed = source
      .withPrefix("z", "z")
      .withPrefix(["0", "1", "2", "3"])

    prefixed
      .subscribe { output in
        record.value.append(output)
      }
      .stage(on: stage)

    let entries: [String] = ["a", "b", "c", "d", "e"]

    for entry in entries {
      source.emit(value: entry)
    }

    XCTAssertEqual(
      ["0", "1", "2", "3", "z", "z", "a", "b", "c", "d", "e"],
      record.value
    )
  }

}
