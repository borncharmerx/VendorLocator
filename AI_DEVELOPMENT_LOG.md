# AI-Assisted Development Log

## Project: Vendor Locator — Senior iOS Technical Assignment

### Overview

AI assistance was used during the development of this project for architectural exploration, implementation guidance, refactoring, and test generation.

The development process was iterative. Requirements were broken into smaller tasks, with each stage building on the previous implementation.

This document summarizes the prompts and engineering decisions that shaped the solution.

### Phase 1 — Initial Architecture

**Prompt:**
> Analyse the assignment and propose a SwiftUI architecture using MVVM, async/await, Google Maps SDK, Google Places SDK, Keychain, and XCTest.

**Goal:** Establish a maintainable project structure with separation of concerns.

### Phase 2 — Google Maps and Places

**Prompt:**
> Update the project to use Google Maps SDK 11.2 and Google Places SDK 11.2.

**Goal:** Integrate the requested Google SDK versions and update deprecated APIs.

### Phase 3 — Mock Vendor Data

**Prompt:**
> List restaurants in Cape Town as vendors in the mock data, including names, addresses and coordinates.

**Goal:** Provide a realistic dataset for demonstrating the vendor list and map markers.

### Phase 4 — Behaviour and Interactor Architecture

**Prompt:**
> Create a Behaviour and Interactor that handle service calls and decide whether to load data from the API or local mock data when the service URL is unavailable.

**Goal:** Separate business logic from the SwiftUI presentation layer and support dependency injection.

### Phase 5 — Vendor Discovery Features

**Prompt:**
> Add vendor details, sorting by distance from the user's location, manual vendor entry with a visible Save button, and directions from the map or details screen.

**Goal:** Improve the vendor discovery experience and support multiple methods of adding vendors.

### Phase 6 — Persistence and Network Monitoring

**Prompt:**
> Add a four-second service delay, persist mock data on the device, route vendor updates through the service layer, and display a full-screen network error when connectivity is lost.

**Goal:** Simulate asynchronous loading, retain local changes and handle network state changes.

### Phase 7 — Architecture Refactoring

**Prompt:**
> Group each View and ViewModel in its own feature folder. Keep Behaviour and Interactor together, separate network and data components, and add independent unit tests for each ViewModel and Interactor.

**Goal:** Improve code organization, testability and maintainability.

### Phase 8 — Map Selection

**Prompt:**
> How can the map automatically show the selected vendor's pin details when the map loads?

**Goal:** Improve coordination between SwiftUI state and Google Maps marker selection.

### Testing and Validation

AI-generated code and recommendations require review and validation.

Validation should include:

- Building the project in Xcode.
- Running the XCTest suite.
- Testing vendor loading, creation and persistence.
- Verifying Google Maps and Places integration.
- Testing location permissions and network disconnection.
- Reviewing security-sensitive code and API-key configuration.

### Reflection

AI was used as a development assistant to explore implementation options, generate initial code and support iterative improvements.

The architectural decisions, implementation details and generated tests are based on assignment requirements
