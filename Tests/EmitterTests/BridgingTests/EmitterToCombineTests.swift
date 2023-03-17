#if canImport(Combine)
import Combine
import Disposable
import Emitter
import XCTest

// MARK: - EmitterToCombineTests

final class EmitterToCombineTests: XCTestCase {

  var cancellables = Set<AnyCancellable>()

  override func setUp() {
    cancellables = Set<AnyCancellable>()
  }

  override func tearDown() async throws { }

  func testSequenceBridge_publishesAsCombinePublisher() async throws {
    let block = AsyncValue<Void>()
    let entries = ["a", "b", "c", "d", "e"]
    var record: [String] = []
    var didFinish = false
    Emitter
      .bridge(entries)
      .asCombinePublisher()
      .sink { _ in
        didFinish = true
        Task { await block.resolve(()) }
      } receiveValue: { value in
        record.append(value)
      }
      .store(in: &cancellables)
    await block.value
    XCTAssertEqual(record, entries)
    XCTAssert(didFinish)
  }

}

// MARK: EmitterToCombineTests.Failure

extension EmitterToCombineTests {
  enum Failure: Error {
    case sourceFail
  }
}
#endif
