import Disposable
import Emitter
import XCTest

// MARK: - AsyncToEmitterTests

final class AsyncToEmitterTests: XCTestCase {

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
    let stream = AsyncStream { continuation in
      for element in entries {
        continuation.yield(element)
      }
      continuation.finish()
    }
    var record: [String] = []
    Emitter.bridge(stream)
      .subscribe { value in
        record.append(value)
      } finished: {
        Task { await self.block.resolve(()) }
      }
      .stage(on: stage)

    await block.value
    XCTAssertEqual(entries, record)
  }

  func testAsyncBridge_publishesAndFinishes_taskEvents() async throws {
    let entries = Array(0 ..< 100)
    let subject = PublishSubject<Int>()
    var record: [Int] = []
    Emitter.bridge(subject.values)
      .subscribe { value in
        record.append(value)
        if record.count == entries.count {
          Task { await self.block.resolve(()) }
        }
      } finished: {
        Task { await self.block2.resolve(()) }
      }
      .stage(on: stage)

    await withTaskGroup(of: Void.self) { group in
      for i in entries {
        group.addTask {
          subject.emit(value: i)
        }
      }
    }

    await block.value
    subject.finish()
    await block2.value
    XCTAssertEqual(entries.sorted(), record.sorted())
  }

}

// MARK: AsyncToEmitterTests.Failure

extension AsyncToEmitterTests {
  enum Failure: Error {
    case sourceFail
  }
}
