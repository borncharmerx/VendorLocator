import XCTest
@testable import VendorLocator

final class VendorLocatorInteractorTests: XCTestCase {
    
    func testMissingURLSelectsLocalSource() {
        XCTAssertNil(VendorAPIConfiguration(baseURLString: nil).vendorsEndpoint)
    }
    
    func testInvalidURLSelectsLocalSource() {
        XCTAssertNil(VendorAPIConfiguration(baseURLString: "not-a-url").vendorsEndpoint)
    }
}
