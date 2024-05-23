#if canImport(Perception)
    import XCTest
    @testable import ObservedCoWBox

    final class ObservedCoWBoxTests: XCTestCase {
        func testInitializationAndWrappedValue() {
            let box = ObservedCoWBox(wrappedValue: 42)
            XCTAssertEqual(box.wrappedValue, 42)
        }

        func testUpdatingWrappedValue() {
            var box = ObservedCoWBox(wrappedValue: 42)
            box.wrappedValue = 100
            XCTAssertEqual(box.wrappedValue, 100)
        }

        func testEquatableConformance() {
            let box1 = ObservedCoWBox(wrappedValue: 42)
            let box2 = ObservedCoWBox(wrappedValue: 42)
            let box3 = ObservedCoWBox(wrappedValue: 100)

            XCTAssertEqual(box1, box2)
            XCTAssertNotEqual(box1, box3)
        }

        func testHashableConformance() {
            let box = ObservedCoWBox(wrappedValue: 42)
            XCTAssertEqual(box.hashValue, 42.hashValue)
        }

        func testEncodableConformance() throws {
            let box = ObservedCoWBox(wrappedValue: 42)
            let encoder = JSONEncoder()
            let data = try encoder.encode(box)
            let jsonString = String(data: data, encoding: .utf8)
            XCTAssertNotNil(jsonString)
        }

        func testDecodableConformance() throws {
            let jsonString = "{\"wrappedValue\":42}"
            let data = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()
            let box = try decoder.decode([String: ObservedCoWBox<Int>].self, from: data)
            XCTAssertEqual(box.values.first!.wrappedValue, 42)
        }

        func testCustomReflectableConformance() {
            let box = ObservedCoWBox(wrappedValue: 42)
            let mirror = box.customMirror
            XCTAssertTrue(mirror.subjectType == Int.self)
        }
    }
#endif
