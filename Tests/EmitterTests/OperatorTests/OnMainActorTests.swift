import Disposable
import Emitter
import XCTest

// MARK: - OnMainActorTests

final class OnMainActorTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func testStream_onMainActor() async throws {
    let record: Unchecked<[String]> = .init([])
    let block = AsyncValue<Void>()
    Emitter.create(String.self) { emit in
      await withTaskGroup(of: Void.self) { group in
        for i in ["a", "b", "c", "d", "e"] {
          group.addTask {
            emit(.value(i))
            XCTAssert(!Thread.isMainThread)
          }
        }
        await group.waitForAll()
        emit(.finished)
      }
    }
    .map { "\($0)-and-stuff" }
    .onMainActor()
    .subscribe { output in
      XCTAssert(Thread.isMainThread)
      record.value.append(output)
    } finished: {
      Task { await block.resolve(()) }
    }
    .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    await block.value

    XCTAssertEqual(
      Set(["a-and-stuff", "b-and-stuff", "c-and-stuff", "d-and-stuff", "e-and-stuff"]),
      Set(record.value)
    )
  }

}
