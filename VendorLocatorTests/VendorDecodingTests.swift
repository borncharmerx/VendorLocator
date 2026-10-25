import XCTest
@testable import VendorLocator

final class VendorDecodingTests: XCTestCase {
    
    func testDecodesVendorCoordinatesFavoriteAndTimestamp() throws {
        let json = """
        {
          "id": "ven-test",
          "name": "Test Vendor",
          "address": "12 Loop Street, Cape Town",
          "coordinate": { "lat": -33.918861, "lng": 18.423300 },
          "isFavorite": true,
          "updatedAt": "2026-10-20T12:00:00Z"
        }
        """.data(using: .utf8)!

        let vendor = try VendorJSONDecoder.make().decode(Vendor.self, from: json)

        XCTAssertEqual(vendor.id, "ven-test")
        XCTAssertEqual(vendor.name, "Test Vendor")
        XCTAssertEqual(vendor.address, "12 Loop Street, Cape Town")
        XCTAssertEqual(vendor.coordinate, VendorCoordinate(latitude: -33.918861, longitude: 18.423300))
        XCTAssertTrue(vendor.isFavorite)
        XCTAssertNotNil(vendor.updatedAt)
    }

    func testInteractorUsesMockWhenServiceURLIsMissing() async throws {
        let expectedVendor = Vendor(
            id: "ven-mock",
            name: "Mock Restaurant",
            address: "12 Loop Street, Cape Town",
            coordinate: VendorCoordinate(latitude: -33.9249, longitude: 18.4241)
        )
        let mockService = StubVendorService(vendors: [expectedVendor])
        let interactor = VendorLocatorInteractor(
            configuration: VendorAPIConfiguration(baseURLString: nil),
            tokenProvider: StubSessionTokenProvider(),
            mockService: mockService,
            delay: NoOpServiceDelay()
        )

        let vendors = try await interactor.loadVendors()

        XCTAssertEqual(vendors, [expectedVendor])
        XCTAssertEqual(mockService.fetchCount, 1)
    }

    func testInvalidServiceURLFallsBackToMockConfiguration() {
        let configuration = VendorAPIConfiguration(baseURLString: "not a url")
        XCTAssertNil(configuration.vendorsEndpoint)
    }

    func testDirectionsURLUsesCoordinatesWhenAvailable() throws {
        let vendor = Vendor(
            id: "ven-directions",
            name: "Directions Vendor",
            address: "12 Loop Street, Cape Town",
            coordinate: VendorCoordinate(latitude: -33.918861, longitude: 18.423300)
        )

        let url = try XCTUnwrap(vendor.directionsURL)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let destination = components.queryItems?.first(where: { $0.name == "destination" })?.value

        XCTAssertEqual(components.host, "www.google.com")
        XCTAssertEqual(destination, "-33.918861,18.4233")
    }

    func testDirectionsURLUsesAddressWhenCoordinatesAreMissing() throws {
        let vendor = Vendor(
            id: "ven-address-directions",
            name: "Address Vendor",
            address: "12 Loop Street, Cape Town",
            coordinate: nil
        )

        let url = try XCTUnwrap(vendor.directionsURL)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let destination = components.queryItems?.first(where: { $0.name == "destination" })?.value

        XCTAssertEqual(destination, "12 Loop Street, Cape Town")
    }

    func testLocalDataServicePersistsAddAndFavoriteUpdateAcrossInstances() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("VendorLocatorTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = temporaryDirectory.appendingPathComponent("vendors.json")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let initial = Vendor(
            id: "ven-existing",
            name: "Existing Cafe",
            address: "1 Loop Street, Cape Town",
            coordinate: VendorCoordinate(latitude: -33.9188, longitude: 18.4233)
        )
        let added = Vendor(
            id: "ven-added",
            name: "New Restaurant",
            address: "2 Loop Street, Cape Town",
            coordinate: nil
        )

        let firstService = LocalVendorDataService(
            fileURL: fileURL,
            delay: NoOpServiceDelay(),
            initialVendors: [initial]
        )
        _ = try await firstService.fetchVendors()
        try await firstService.saveVendor(added)
        var favoriteAdded = added
        favoriteAdded.isFavorite = true
        try await firstService.updateVendor(favoriteAdded)

        let reopenedService = LocalVendorDataService(
            fileURL: fileURL,
            delay: NoOpServiceDelay(),
            initialVendors: []
        )
        let persistedVendors = try await reopenedService.fetchVendors()

        XCTAssertEqual(persistedVendors.count, 2)
        XCTAssertTrue(persistedVendors.contains(where: { $0.id == "ven-added" && $0.isFavorite }))
        XCTAssertTrue(persistedVendors.contains(where: { $0.id == "ven-existing" }))
    }

    @MainActor
    func testStoreRoutesCreateAndFavoriteUpdatesThroughBehaviour() async throws {
        
        let behaviour = RecordingVendorLocatorBehaviour()
        let store = VendorLocatorStore(behaviour: behaviour)
        await store.loadVendors()

        let vendor = Vendor(
            id: "store-boundary-test",
            name: "Boundary Test Cafe",
            address: "15 Loop Street, Cape Town",
            coordinate: VendorCoordinate(latitude: -33.9188, longitude: 18.4233)
        )
        try await store.addVendor(vendor)
        await store.toggleFavorite(for: vendor)

        XCTAssertTrue(store.vendors.first(where: { $0.id == vendor.id })?.isFavorite == true)
        let metrics = await behaviour.metrics()
        XCTAssertEqual(metrics.saveCount, 1)
        XCTAssertEqual(metrics.updateCount, 1)
    }

    func testServiceDelayDefaultsToFourSeconds() {
        XCTAssertEqual(FixedServiceDelay.defaultDurationNanoseconds, 4_000_000_000)
        XCTAssertEqual(FixedServiceDelay().durationNanoseconds, 4_000_000_000)
    }

    func testLocalDataServiceWaitsThroughInjectedDelayForEveryOperation() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("VendorLocatorDelayTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = temporaryDirectory.appendingPathComponent("vendors.json")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let vendor = Vendor(id: "delay-test", name: "Delay Cafe", address: "3 Loop Street", coordinate: nil)
        let delay = CountingServiceDelay()
        let service = LocalVendorDataService(
            fileURL: fileURL,
            delay: delay,
            initialVendors: [vendor]
        )

        _ = try await service.fetchVendors()
        try await service.saveVendor(Vendor(id: "delay-add", name: "Added Cafe", address: "4 Loop Street", coordinate: nil))
        var updated = vendor
        updated.isFavorite = true
        try await service.updateVendor(updated)

        let calls = await delay.waitCount
        XCTAssertEqual(calls, 3)
    }
}

private actor RecordingVendorLocatorBehaviour: VendorLocatorBehaviour {
    
    private var vendors: [Vendor] = []
    private var saveCount = 0
    private var updateCount = 0

    func loadVendors() async throws -> [Vendor] {
        vendors
    }

    func saveVendor(_ vendor: Vendor) async throws {
        if let index = vendors.firstIndex(where: { $0.id == vendor.id }) {
            vendors[index] = vendor
        } else {
            vendors.insert(vendor, at: 0)
        }
        saveCount += 1
    }

    func updateVendor(_ vendor: Vendor) async throws {
        guard let index = vendors.firstIndex(where: { $0.id == vendor.id }) else {
            throw VendorServiceError.vendorNotFound(vendor.id)
        }
        vendors[index] = vendor
        updateCount += 1
    }

    func metrics() -> (saveCount: Int, updateCount: Int) {
        (saveCount, updateCount)
    }
}

private struct StubSessionTokenProvider: SessionTokenProviding {
    
    func readToken() throws -> String? { nil }
}

private struct NoOpServiceDelay: ServiceDelayProviding {
    func wait() async throws {}
}

private actor CountingServiceDelay: ServiceDelayProviding {
    
    private(set) var waitCount = 0

    func wait() async throws {
        waitCount += 1
    }
}

private final class StubVendorService: VendorServicing {
    
    private let vendors: [Vendor]
    private(set) var fetchCount = 0

    init(vendors: [Vendor]) {
        self.vendors = vendors
    }

    func fetchVendors() async throws -> [Vendor] {
        fetchCount += 1
        return vendors
    }

    func saveVendor(_ vendor: Vendor) async throws {}
    func updateVendor(_ vendor: Vendor) async throws {}
}
