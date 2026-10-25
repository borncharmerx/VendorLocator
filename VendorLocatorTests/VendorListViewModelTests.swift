import XCTest
import CoreLocation
@testable import VendorLocator

@MainActor final class VendorListViewModelTests: XCTestCase {
    
    func testDefaultSortingIsUnchanged() {
        let store = VendorLocatorStore(behaviour: TestVendorBehaviour());
        let vm = VendorListViewModel(store: store);
        XCTAssertFalse(vm.sortByNearest); XCTAssertEqual(vm.displayedVendors(userLocation: nil).count, 0)
    }
}
