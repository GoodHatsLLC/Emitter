import Disposable
import Emitter
import XCTest

// MARK: - ThreadingTests

final class ThreadingTests: XCTestCase {
  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func testThreading_publishSubject() async throws {
    let lock = NSLock()
    let subject = PublishSubject<Void>()
    let asyncValue = AsyncValue<Int>()
    var count = 0
    subject
      .subscribe { _ in
        lock.lock()
        count += 1
        let count = count
        lock.unlock()
        XCTAssert(count <= 10000)
        if count == 10000 {
          Task {
            await asyncValue.resolve(count)
          }
        }
      }
      .stage(on: stage)
    XCTAssertEqual(0, count)
    await withTaskGroup(of: Void.self) { group in
      for _ in 0 ..< 10000 {
        group.addTask(priority: .background) {
          subject.emit(value: ())
        }
      }
      await group.waitForAll()
    }
    let finalValue = await asyncValue.value
    XCTAssertEqual(10000, finalValue)
  }

  func testThreading_valueSubject() async throws {
    let lock = NSLock()
    let subject = ValueSubject<Void>(())
    let asyncValue = AsyncValue<Int>()
    let asyncIsReady = AsyncValue<Void>()
    var count = 0
    subject
      .subscribe { _ in
        lock.lock()
        count += 1
        let count = count
        lock.unlock()
        if count == 1 {
          Task { await asyncIsReady.resolve(()) }
        }
        XCTAssert(count <= 10000)
        if count == 10000 {
          let count = count
          Task {
            await asyncValue.resolve(count)
          }
        }
      }
      .stage(on: stage)
    _ = await asyncIsReady.value
    await withTaskGroup(of: Void.self) { group in
      for _ in 1 ..< 10000 {
        group.addTask(priority: .background) {
          subject.emit(value: ())
        }
      }
      await group.waitForAll()
    }
    let finalValue = await asyncValue.value
    XCTAssertEqual(10000, finalValue)
  }
}
