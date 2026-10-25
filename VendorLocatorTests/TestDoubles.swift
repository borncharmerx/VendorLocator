import Foundation
@testable import VendorLocator

actor TestVendorBehaviour: VendorLocatorBehaviour {
    
 func loadVendors() async throws -> [Vendor] { [] }
 func saveVendor(_ vendor: Vendor) async throws {}
 func updateVendor(_ vendor: Vendor) async throws {}
}

struct TestTokenStore: SessionTokenStoring {
    
 func saveToken(_ token: String) throws {}
 func readToken() throws -> String? { nil }
 func clearToken() throws {}
}
