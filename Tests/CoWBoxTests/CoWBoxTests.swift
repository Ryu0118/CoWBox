import XCTest
@testable import CoWBox

final class CoWBoxTests: XCTestCase {
    private var test: Test!

    override func setUp() {
        test = .init()
    }

    func testCowBox() throws {
        test.hoge = 1
        XCTAssertEqual(test.hoge, 1)
    }

    struct Test {
        @CoWBox var hoge: Int = 0
    }
}
