# Solution Notes

## Architecture

The implementation keeps responsibilities intentionally small and separated:

- **Model — `Vendor` / `VendorCoordinate`:** Codable value types matching the vendor JSON shape. Coordinates map from `lat` and `lng`; timestamps use ISO-8601 decoding. The bundled fixture contains 137 curated Cape Town restaurants/eateries across the CBD, Waterfront, Atlantic Seaboard, Southern Peninsula, and selected northern/southern suburbs.
- **Behaviour — `VendorLocatorBehaviour`:** an async CRUD boundary for loading, saving, and updating vendors. Presentation code does not know where data comes from.
- **Interactor — `VendorLocatorInteractor`:** chooses `LocalVendorDataService` if `VendorAPIBaseURL` is missing, blank, or invalid; otherwise it creates `HTTPVendorService`. A runtime HTTP failure remains an error rather than silently switching sources.
- **Services — `VendorServicing`, `LocalVendorDataService`, and `HTTPVendorService`:** a shared async CRUD contract, a device-local JSON store seeded from the bundled 137-vendor fixture on first launch, and a REST adapter using `URLSession.data(for:)` with async/await. `LocalVendorDataService` persists all writes to `Documents/vendors.json`. Both concrete services use an injectable delay set to four seconds by default.
- **Shared state — `VendorLocatorStore`:** a main-actor observable coordinator maintains the vendor collection, loading/error state, and selected vendor ID. Mutations go through the Behaviour/service layer before the view state is finalized.
- **Screen-specific view models:** `VendorListViewModel`, `MapScreenViewModel`, `VendorDetailViewModel`, `ManualVendorEntryViewModel`, `PlaceSearchViewModel`, and `SettingsViewModel` isolate screen presentation, validation, selection, and Keychain operations. The list and map subscribe to shared-store changes so they stay synchronized.
- **Map adapter — `GoogleMapView`:** wraps `GMSMapView` in `UIViewRepresentable`, renders a marker per coordinate, styles favorites, and animates the camera when selection changes. The selected-marker panel links to vendor details and Google Maps directions.
- **Location — `VendorLocationManager`:** encapsulates Core Location permission and one-shot location requests. `VendorListView` can sort by straight-line distance when a location is available and shows a status/retry message when permission is denied or location is unavailable. The app declares `NSLocationWhenInUseUsageDescription`.
- **Details and manual entry — `VendorDetailView` / `ManualVendorEntryView`:** details show the address and coordinates and provide map/directions actions. Manual entry validates required name/address fields and optional latitude/longitude, with both toolbar Save and a prominent on-form Save vendor button.
- **Places enhancement:** the project pins both Google SDK packages to **11.2.0** and links the `GooglePlacesSwift` product from `ios-places-sdk`. The live branch uses the Places Swift SDK's `.placeAutocomplete` widget, then performs an async `FetchPlaceRequest` for display name, formatted address, and coordinates. The selected result is transformed into a new `Vendor`. This avoids `GMSAutocompleteViewController`, which was removed in Places SDK 11.0. When no Google key is configured, a deterministic local sample search keeps the flow demonstrable without a live API call.
- **Network monitor — `NetworkMonitor`:** uses `NWPathMonitor` at the app root. When the path becomes unsatisfied, a non-dismissible full-screen offline state covers the application; the state automatically closes when the path is satisfied again.
- **Security — `KeychainTokenStore`:** saves the token as a generic-password Keychain item, accessible only while the device is unlocked and not migrated to another device. The optional HTTP client reads the token only when constructing the authorization header.

## Data flow

1. `ContentView` creates one `VendorLocatorStore`, then injects it into screen-specific view models so the list and map present the same vendor collection.
2. `VendorLocatorStore` calls `VendorLocatorBehaviour`. The `VendorLocatorInteractor` selects the REST service for a valid configured URL or `LocalVendorDataService` otherwise.
3. In local mode, the first operation seeds `Documents/vendors.json` from bundled `Resources/vendors.json`; future fetches, additions, and favorite updates use the persisted file. In REST mode, fetch uses GET `/vendors`, create uses POST `/vendors`, and update uses PUT `/vendors/{id}` with the Keychain token when available.
4. Each service operation waits four seconds by default. This intentionally exposes loading, saving, and updating states during the demo; tests inject a no-op delay.
5. `VendorListViewModel` owns nearest-first sort state and calculates straight-line distance for geocoded vendors. `MapScreenViewModel` observes shared selection and data state. Screen-level view models also isolate vendor details, manual-entry validation, Places additions, and Settings token operations.
6. `NetworkMonitor` watches `NWPathMonitor`. A disconnected path presents a full-screen error over the app; once the system reports a satisfied path, the presentation binding becomes false and the error screen is removed.
7. The add-vendor sheet offers Google Places/mock search and manual entry. Both routes call the store's service-backed add method, so local mock additions are saved to `Documents/vendors.json`. Details and map panels provide Google Maps directions.

## Error and loading states

- Empty initial load shows a progress indicator; the four-second service delay makes this state easy to demonstrate.
- Empty failed load shows the error and a retry action.
- A failed refresh while vendors are already visible keeps the existing list and shows a non-blocking warning.
- HTTP non-2xx responses become a user-readable service error.
- A missing Google API key does not prevent the list/settings/mock Place Search from running; the Map tab explains the setup step instead of instantiating an unconfigured Google map.
- A missing coordinate is handled by skipping marker creation and labelling the vendor in the list. Manual entry can omit coordinates; such vendors can still use address-based directions.
- Location permission denial or location lookup errors do not block browsing; the list explains why nearest-first sorting cannot yet calculate distances and offers a retry. Distance is straight-line distance, not route distance or travel time.

## Secure token decisions

The session token is stored in Keychain using `kSecClassGenericPassword`, `kSecAttrService`, and `kSecAttrAccount`. `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` limits access to an unlocked device and prevents migration to another device. The token is never stored in `UserDefaults` and the code does not log it. `SettingsView` uses a `SecureField`; the explicit “Load saved” action loads it back into the masked field. In a production app I would also consider token rotation/expiry handling, access-group needs, and server-side revocation.

## Places enhancement choice

I chose **Place search** (rather than address-to-coordinates) because it gives a user a complete discovery flow: search by name/address, select an actual Google result, create a vendor with coordinates, and see its marker. The live integration uses the Google Places Swift autocomplete widget so Google attribution is handled by the SDK UI. The mock branch is deliberately deterministic and only used when no API key is configured.

To enable the live path, create a Google Cloud project with billing enabled, enable Maps SDK for iOS and **Places API (New)**, set a bundle-ID-restricted API key in the ignored `Config/Local.xcconfig`, and run on a device/simulator with internet. This project pins the Maps and Places packages to exact version **11.2.0**. Google's setup documentation currently requires **Xcode 26.0 or later** for these versions. The Places autocomplete widget manages the selection session and supplies the required Google attribution UI. Check the current Google Maps Platform terms, usage limits, and pricing before shipping.

## Trade-offs and limitations

- The assignment permits a bundled JSON source, which avoids depending on a separately deployed server. The HTTP service shows the REST boundary and is selected by a configuration value. The 137-row restaurant file is a curated mock list, not an exhaustive/live listing of every Cape Town restaurant. Its coordinates are approximate neighbourhood-level demo points; production data should use verified coordinates from Places or a maintained business dataset.
- In mock mode, vendors and favorite changes persist locally as JSON in the app Documents directory. When REST mode is configured, durable storage is owned by the backend and depends on its API implementation.
- The four-second service delay applies to fetch, create, and update requests by design. Production latency would usually come from the backend and this artificial delay should be removed or changed via dependency injection.
- The local JSON file is the mock-mode persistence layer; there is no separate stale-while-revalidate cache, pagination, clustering, or bidirectional marker-selection system.
- Google API keys embedded in an iOS application are extractable, so the key must be restricted. The sample configuration is ignored by Git to reduce accidental disclosure.
- I could not execute Xcode builds or simulator tests in this non-macOS environment. Run dependency resolution, build, Places autocomplete, live map behavior, and the focused XCTest in Xcode 26+ before submitting. SDK API usage has been aligned to the current 11.2-era documentation, but a successful compile/run has not been verified here.

## Focused tests

`VendorDecodingTests` checks JSON decoding, coordinate key mapping, favorites, and ISO-8601 dates; interactor source selection; create/favorite service routing through the shared store; directions URL construction; the four-second default delay; and persistence of vendor creation and favorite updates across new `LocalVendorDataService` instances. The persistence test injects a temporary Documents-style file URL and a no-op delay. Run the complete XCTest suite in Xcode 26+; this environment does not include Xcode or an iOS Simulator.


### Feature folders and address-only markers

Feature folders colocate each screen's SwiftUI View and ViewModel. Interactor/Behaviour share an Interactors folder; HTTP/network monitoring live under Network and local persistence/storage under Data. Address-only vendors retain text-based Google Maps directions; the map uses Core Location geocoding for missing coordinates and caches results for the current map session. This is a best-effort fallback, not guaranteed geocoding. Unit tests have separate files for the six screen view models and the interactor; full XCTest execution requires macOS/Xcode.
