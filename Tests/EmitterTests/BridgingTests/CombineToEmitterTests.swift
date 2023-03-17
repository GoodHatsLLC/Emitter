#if canImport(Combine)
import Combine
import Disposable
import Emitter
import XCTest

// MARK: - CombineToEmitterTests

final class CombineToEmitterTests: XCTestCase {

  let stage = DisposableStage()
  var block: AsyncValue<Void>!
  var block2: AsyncValue<Void>!

  override func setUp() {
    block = .init()
    block2 = .init()
  }

  override func tearDown() async throws {
    stage.reset()
  }

  func testAsyncBridge_publishesAndFinishes() async throws {
    let entries = ["a", "b", "c", "d", "e"]
    var record: [String] = []
    Emitter.bridge(entries.publisher)
      .subscribe { value in
        record.append(value)
      } finished: {
        Task { await self.block.resolve(()) }
      }
      .stage(on: stage)

    await block.value
    XCTAssertEqual(entries, record)
  }

  func testAsyncBridge_publishesAndFinishes_combinePublisher_synchronously() async throws {
    let entries = Array(0 ..< 100)
    let subject = PassthroughSubject<Int, Never>()
    var record: [Int] = []
    Emitter.bridge(subject)
      .subscribe { value in
        record.append(value)
        if record.count == entries.count {
          Task { await self.block.resolve(()) }
        }
      } finished: {
        Task { await self.block2.resolve(()) }
      }
      .stage(on: stage)

    for i in entries {
      subject.send(i)
    }
    subject.send(completion: .finished)

    await block.value
    XCTAssertEqual(entries.sorted(), record.sorted())
  }

}

// MARK: CombineToEmitterTests.Failure

extension CombineToEmitterTests {
  enum Failure: Error {
    case sourceFail
  }
}
#endif
