import XCTest
@testable import VendorLocator

@MainActor final class SettingsViewModelTests: XCTestCase {
    
    func testEmptyTokenCannotBeSaved() {
        let vm = SettingsViewModel(tokenStore: TestTokenStore());
        vm.saveToken();
        XCTAssertFalse(vm.hasSavedToken)
    }
}
