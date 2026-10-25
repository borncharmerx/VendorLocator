import XCTest
@testable import VendorLocator

@MainActor final class MapScreenViewModelTests: XCTestCase {
    
    func testInitiallyNoSelection() {
        let vm = MapScreenViewModel(store: VendorLocatorStore(behaviour: TestVendorBehaviour()));
        XCTAssertNil(vm.selectedVendorID); XCTAssertNil(vm.selectedVendor)
    }
}
