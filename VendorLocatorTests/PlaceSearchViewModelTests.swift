import XCTest
@testable import VendorLocator

@MainActor final class PlaceSearchViewModelTests: XCTestCase {
    
    func testMockSearchFiltersByName() {
        let vm = PlaceSearchViewModel(store: VendorLocatorStore(behaviour: TestVendorBehaviour()));
        vm.query = "Canto";
        
        XCTAssertEqual(vm.filteredMockPlaces.count, 1);
        XCTAssertEqual(vm.filteredMockPlaces.first?.name, "Canto Wines")
    }
}
