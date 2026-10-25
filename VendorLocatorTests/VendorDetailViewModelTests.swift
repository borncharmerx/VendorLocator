import XCTest
@testable import VendorLocator

@MainActor final class VendorDetailViewModelTests: XCTestCase {
    
    func testAddressOnlyVendorHasDirectionsAndShowMapCallback() {
        var called = false;
        let vendor = Vendor(id:"test", name:"Test", address:"12 Loop Street, Cape Town", coordinate:nil);
        
        let vm = VendorDetailViewModel(vendor:vendor, onShowOnMap:{ called = true });
        XCTAssertTrue(
            vm.directionsURL?.absoluteString.contains("12%20Loop") == true
            || vm.directionsURL?.absoluteString.contains("12+Loop") == true
        );
        vm.showOnMap(); XCTAssertTrue(called)
    }
}
