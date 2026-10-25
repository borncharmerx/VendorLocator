import XCTest
@testable import VendorLocator

@MainActor final class ManualVendorEntryViewModelTests: XCTestCase {
    
    func testRequiresNameAndAddressButNotCoordinates() {
        let vm = ManualVendorEntryViewModel(store: VendorLocatorStore(behaviour: TestVendorBehaviour()));
        
        XCTAssertFalse(vm.canSave);
        
        vm.name = "Coffee";
        
        XCTAssertFalse(vm.canSave);
        
        vm.address = "Loop Street, Cape Town";
        
        XCTAssertTrue(vm.canSave)
    }
}
