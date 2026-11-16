#if canImport(Perception)
    import Observation
    import Perception
    import XCTest
    @testable import ObservedCoWBox

    final class ObservedCoWBoxCopyOnWriteTests: XCTestCase {
        // Bug detected: setter reports "shared" even when uniquely held, re-allocating Storage on every write.
        func testUniquelyHeldBoxKeepsStorageIdentityAcrossWrite() {
            var box = ObservedCoWBox(wrappedValue: 0)
            let before = storageID(of: box)
            box.wrappedValue = 1
            XCTAssertEqual(storageID(of: box), before)
            XCTAssertEqual(box.wrappedValue, 1)
        }

        // Bug detected: Storage is re-created on later writes even if the first one was in place.
        func testUniquelyHeldBoxKeepsStorageIdentityAcrossManyWrites() {
            var box = ObservedCoWBox(wrappedValue: 0)
            let before = storageID(of: box)
            for value in 1...5 {
                box.wrappedValue = value
                XCTAssertEqual(storageID(of: box), before)
            }
            XCTAssertEqual(box.wrappedValue, 5)
        }

        // Bug detected: a copy is not recognized as sharing storage right after copying.
        func testCopySharesStorageUntilWritten() {
            let original = ObservedCoWBox(wrappedValue: 1)
            let copy = original
            XCTAssertTrue(original.sharesStorage(with: copy))
        }

        // Bug detected: writing to a shared box mutates the other holder's value (missing copy-on-write).
        func testWritingToCopyDoesNotChangeOriginal() {
            let original = ObservedCoWBox(wrappedValue: 1)
            var copy = original
            copy.wrappedValue = 2
            XCTAssertEqual(original.wrappedValue, 1)
            XCTAssertEqual(copy.wrappedValue, 2)
            XCTAssertFalse(original.sharesStorage(with: copy))
        }

        // Bug detected: writing to the original mutates the copy (COW applied in only one direction).
        func testWritingToOriginalDoesNotChangeCopy() {
            var original = ObservedCoWBox(wrappedValue: 1)
            let copy = original
            original.wrappedValue = 2
            XCTAssertEqual(copy.wrappedValue, 1)
            XCTAssertEqual(original.wrappedValue, 2)
            XCTAssertFalse(original.sharesStorage(with: copy))
        }

        // Bug detected: after separating from a shared storage, the writer keeps re-allocating on later writes
        // (or still points to the old storage).
        func testWriterKeepsOwnStorageAfterSeparating() {
            let original = ObservedCoWBox(wrappedValue: 1)
            var copy = original
            copy.wrappedValue = 2
            let separated = storageID(of: copy)
            copy.wrappedValue = 3
            XCTAssertEqual(storageID(of: copy), separated)
            XCTAssertEqual(copy.wrappedValue, 3)
            XCTAssertEqual(original.wrappedValue, 1)
        }

        // Bug detected: a copy that is dropped leaves the original considered shared (stale reference held).
        func testOriginalBecomesUniqueAgainAfterCopyIsReleased() {
            var original = ObservedCoWBox(wrappedValue: 1)
            do {
                let copy = original
                XCTAssertTrue(original.sharesStorage(with: copy))
            }
            let before = storageID(of: original)
            original.wrappedValue = 2
            XCTAssertEqual(storageID(of: original), before)
        }

        // Regression: perception observers must be notified on a write when uniquely held.
        func testPerceptionTrackingNotifiedOnUniqueWrite() {
            var box = ObservedCoWBox(wrappedValue: 0)
            var changeCount = 0
            withPerceptionTracking {
                _ = box.wrappedValue
            } onChange: {
                changeCount += 1
            }
            box.wrappedValue = 1
            XCTAssertEqual(changeCount, 1)
        }

        // Regression: perception observers must be notified on a write when storage is shared.
        func testPerceptionTrackingNotifiedOnSharedWrite() {
            var box = ObservedCoWBox(wrappedValue: 0)
            let copy = box
            var changeCount = 0
            withPerceptionTracking {
                _ = box.wrappedValue
            } onChange: {
                changeCount += 1
            }
            box.wrappedValue = 1
            XCTAssertEqual(changeCount, 1)
            XCTAssertEqual(copy.wrappedValue, 0)
        }

        // Regression: Observation observers (iOS 17 / macOS 14+) must be notified on a unique write.
        @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
        func testObservationTrackingNotifiedOnUniqueWrite() {
            var box = ObservedCoWBox(wrappedValue: 0)
            var changeCount = 0
            withObservationTracking {
                _ = box.wrappedValue
            } onChange: {
                changeCount += 1
            }
            box.wrappedValue = 1
            XCTAssertEqual(changeCount, 1)
        }

        // Regression: Observation observers must be notified on a shared write.
        @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
        func testObservationTrackingNotifiedOnSharedWrite() {
            var box = ObservedCoWBox(wrappedValue: 0)
            let copy = box
            var changeCount = 0
            withObservationTracking {
                _ = box.wrappedValue
            } onChange: {
                changeCount += 1
            }
            box.wrappedValue = 1
            XCTAssertEqual(changeCount, 1)
            XCTAssertEqual(copy.wrappedValue, 0)
        }

        // The box customizes its Mirror (it reflects the wrapped value) and `storage` is private, so reflection
        // cannot reveal the Storage reference. Instead, snapshot the raw words of the box (no retain, no copy of the
        // box). Writing the wrapped value in place leaves the wrapper's stored properties, including the Storage
        // reference, bit-for-bit identical; swapping in a new Storage changes the snapshot.
        private func storageID<State>(of box: ObservedCoWBox<State>) -> [UInt] {
            withUnsafeBytes(of: box) { raw in
                (0..<raw.count / MemoryLayout<UInt>.size).map {
                    raw.loadUnaligned(fromByteOffset: $0 * MemoryLayout<UInt>.size, as: UInt.self)
                }
            }
        }
    }
#endif
