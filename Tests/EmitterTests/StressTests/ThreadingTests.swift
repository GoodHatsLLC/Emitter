import Disposable
import Emitter
import XCTest

// MARK: - ThreadingTests

final class ThreadingTests: XCTestCase {
  let stage = DisposableStage()

  override func setUp() {}

  override func tearDown() {
    stage.reset()
  }

  func testThreading_publishSubject() async throws {
    let lock = NSLock()
    let subject = PublishSubject<()>()
    let asyncValue = AsyncValue(Int.self)
    var count = 0
    subject
      .subscribe { _ in
        lock.lock()
        count += 1
        let count = count
        lock.unlock()
        XCTAssert(count <= 10_000)
        if count == 10_000 {
          Task {
            asyncValue.resolve(count)
          }
        }
      }
      .stage(on: stage)
    XCTAssertEqual(0, count)
    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<10_000 {
        group.addTask(priority: .background) {
          subject.emit(.value(()))
        }
      }
      await group.waitForAll()
    }
    let finalValue = await asyncValue.value
    XCTAssertEqual(10_000, finalValue)
  }

  func testThreading_valueSubject() async throws {
    let lock = NSLock()
    let subject = ValueSubject<()>(())
    let asyncValue = AsyncValue(Int.self)
    let asyncIsReady = AsyncValue<()>()
    var count = 0
    subject
      .subscribe { _ in
        lock.lock()
        count += 1
        let count = count
        lock.unlock()
        if count == 1 {
          asyncIsReady.resolve(())
        }
        XCTAssert(count <= 10_000)
        if count == 10_000 {
          let count = count
          Task {
            asyncValue.resolve(count)
          }
        }
      }
      .stage(on: stage)
    _ = await asyncIsReady.value
    await withTaskGroup(of: Void.self) { group in
      for _ in 1..<10_000 {
        group.addTask(priority: .background) {
          subject.emit(.value(()))
        }
      }
      await group.waitForAll()
    }
    let finalValue = await asyncValue.value
    XCTAssertEqual(10_000, finalValue)
  }
}
