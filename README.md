# Vendor Locator (Senior iOS Take-Home)

A small SwiftUI app for browsing vendors, placing them on Google Maps, adding places through Google Places, and managing an API session token in the iOS Keychain.

## Features

- Vendor list loaded asynchronously through a Behaviour/Interactor boundary; optional HTTP REST endpoint support.
- Every vendor service operation has an intentional **4-second delay** to demonstrate loading/saving states; the delay is injectable so unit tests can stay fast.
- In mock mode, bundled JSON seeds `Documents/vendors.json` on first launch. Additions and favorite updates are written to device-local storage and survive app relaunches.
- Reload button and pull-to-refresh, loading indicator, and friendly error states.
- Favorites update through the service layer and persist in local mock mode.
- Vendor detail screen showing address and coordinates, with actions to show the vendor on the map or open Google Maps directions.
- Optional nearest-first sorting using the device location, including a permission explanation and distance labels.
- Add-vendor flow offers Google Places/mock place search and manual entry; manual entry has an explicit visible Save button and optional coordinates.
- Google Maps iOS SDK markers, favorite marker styling, and camera recentering when a vendor is selected.
- One Google Places enhancement: search for a place and add it as a vendor. Uses the `GooglePlacesSwift` autocomplete widget and async Place Details when configured; provides deterministic sample results without an API key.
- App-wide network monitoring using `NWPathMonitor`; a full-screen offline message appears when the network path disconnects and disappears automatically when connectivity returns.
- Separate screen view models for list sorting, map selection, vendor details, manual entry, Places search, and Settings, coordinated through a shared `VendorLocatorStore`.
- Keychain settings to save, read, and clear the session token.
- HTTP client attaches the saved token as an `Authorization: Bearer ...` header when a REST endpoint is configured.
- XCTest coverage for vendor JSON decoding, source selection, Behaviour/Interactor store routing, four-second default service delay, and persistence of added vendors/favorite changes across local-service instances.
- Semantic SwiftUI styling follows system light/dark mode automatically.
- Bundled fixture data contains **137 curated Cape Town restaurant and eatery entries**, covering the CBD and selected nearby areas/suburbs.

## Requirements

- macOS with Xcode 26.0 or later (required by Google Maps SDK 11.2.0 and Places SDK 11.2.0)
- iOS 16+ deployment target
- Internet access to resolve Swift Package Manager dependencies
- A Google Maps Platform API key to render the live map and use live Places search. The project can launch without a key; map UI switches to a setup notice and Places uses mock results.

## Open and run

1. Clone this repository and open `VendorLocator.xcodeproj` in Xcode.
2. Xcode resolves two SPM packages:
   - Maps: `https://github.com/googlemaps/ios-maps-sdk` pinned to **11.2.0** (product: `GoogleMaps`)
   - Places: `https://github.com/googlemaps/ios-places-sdk` pinned to **11.2.0** (product: `GooglePlacesSwift`)
   - Both dependencies use exact-version Swift Package Manager rules. Places 11.2 uses the modern Swift-native API; the older `GMSAutocompleteViewController` was removed in Places 11.0.
3. For the mock-data path, build and run on an iOS 16+ simulator. The Cape Town restaurant fixtures are in `VendorLocator/Resources/vendors.json` (137 entries). The initial map camera is zoomed out to show the broader sample area.
4. To enable live Google Maps and Places, create a restricted iOS key in Google Cloud Console and enable **Maps SDK for iOS** and **Places API (New)** for the same project. All keys are on Base.xcconfig

5. In Xcode, choose the `VendorLocator` scheme and run.

## Mock restaurant dataset notes

The bundled JSON is a **curated demo dataset, not a complete or live directory of every Cape Town restaurant**. It includes venues drawn from the Cape Town Central City Improvement District's [CBD Eateries map](https://www.capetownccid.com/ccid-maps) and additional well-known restaurants across areas such as the V&A Waterfront, Gardens, Sea Point, Camps Bay, Constantia, Kalk Bay, Hout Bay, Woodstock, Newlands, Parklands, and Durbanville. Listings and operating status can change over time.

Coordinates are **approximate demo points within their respective neighbourhoods**, used to populate markers and exercise selection/camera behaviour. They are not guaranteed to be the precise entrance/location of each restaurant. For a production dataset, source verified coordinates from Google Places or a maintained restaurant API and refresh venue status/address data.

## Optional REST backend

The screen-specific view models operate through a shared `VendorLocatorStore`, which calls the `VendorLocatorBehaviour` boundary. `VendorLocatorInteractor` owns source selection: when `VendorAPIBaseURL` is missing, blank, or invalid, it uses `LocalVendorDataService`, which seeds the app Documents directory from bundled JSON on first launch and persists future changes to `Documents/vendors.json`. To use an HTTP source, set `VENDOR_API_BASE_URL` in `Config/Local.xcconfig`, for example:

```xcconfig
VENDOR_API_BASE_URL = https://api.example.com
```

The interactor creates `HTTPVendorService` and issues `GET https://api.example.com/vendors`, sends `Accept: application/json`, and adds `Authorization: Bearer <saved-token>` only when a token exists in Keychain. HTTP operations support `POST /vendors` for creation and `PUT /vendors/{id}` for updates. All local and HTTP service operations wait four seconds by default. The response body must be a JSON array in the same shape as `vendors.json`. The sample endpoint above is illustrative; no remote backend is provided by this repository. When a valid URL is configured but the request fails, the error is shown to the user rather than silently falling back to mock data; only a missing/invalid URL selects the mock source.

## Run the test

In Xcode, select the `VendorLocator` scheme and use **Product → Test** (⌘U). The tests validate JSON decoding, coordinate key mapping (`lat`/`lng`), date decoding, no-URL source selection, create/favorite routing through the Behaviour boundary, the four-second default delay setting, and persistence of created vendors and favorite updates across newly instantiated local service objects. A simulator runtime must be installed.

## Repository layout

```text
VendorLocator/
├── Features/
│   ├── VendorList/
│   │   ├── VendorListView.swift
│   │   └── VendorListViewModel.swift
│   ├── MapScreen/
│   │   ├── MapScreenView.swift
│   │   ├── MapScreenViewModel.swift
│   │   └── GoogleMapView.swift
│   ├── VendorDetail/
│   ├── ManualVendorEntry/
│   ├── PlaceSearch/
│   └── Settings/
│
├── Interactors/
│   ├── VendorLocatorBehaviour.swift
│   └── VendorLocatorInteractor.swift
│
├── Network/
│   ├── VendorService.swift
│   └── NetworkMonitor.swift
│
├── Data/
│   ├── LocalVendorDataService.swift
│   ├── VendorLocatorStore.swift
│   ├── KeychainTokenStore.swift
│   └── VendorLocationManager.swift
│
├── Models/
├── Configuration/
└── Resources/
```
