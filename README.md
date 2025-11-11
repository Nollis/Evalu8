# Evalu8

A collaborative decision-making application rebuilt from Factor with a clean architecture.

## Overview

Evalu8 helps individuals and teams make better decisions through structured evaluation of options against weighted criteria. The app combines systematic decision analysis with real-time collaboration and visual analytics.

## Architecture

Evalu8 follows a clean architecture pattern with clear separation between layers:

- **Domain**: Core business logic, models, and domain services
- **Data**: Data persistence, CloudKit integration, repository implementations
- **Presentation**: SwiftUI views, view models, and UI components
- **Supporting**: Shared utilities, extensions, and constants

See [EVALU8_ARCHITECTURE.md](EVALU8_ARCHITECTURE.md) for detailed architecture documentation.

## Project Setup

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target (for enhanced AI/ML capabilities)
- Apple Developer account (for CloudKit)

### Initial Setup

1. **Create Xcode Project**:
   - Open Xcode
   - Create a new iOS App project
   - Name: `Evalu8`
   - Bundle Identifier: `com.nollis.evalu8`
   - Interface: SwiftUI
   - Language: Swift
   - Storage: Core Data (we'll configure CloudKit separately)

2. **Configure CloudKit**:
   - In Xcode, select the project target
   - Go to "Signing & Capabilities"
   - Add "CloudKit" capability
   - Container Identifier: `iCloud.com.nollis.evalu8`

3. **Add Files to Project**:
   - Add all files from the `Domain/`, `Data/`, `Presentation/`, and `Supporting/` directories
   - Ensure the Core Data model (`Evalu8.xcdatamodeld`) is added to the target
   - Copy `Resources/Assets.xcassets` to the project

4. **Configure Info.plist**:
   - Set minimum iOS version to 17.0
   - Configure URL schemes if needed for deep linking

5. **Build and Run**:
   - Build the project (⌘B)
   - Run on simulator or device (⌘R)

## Migration from Factor

This project is a complete rebuild of Factor with:
- Cleaner architecture and naming conventions
- Improved separation of concerns
- Better error handling
- Removed debug code
- Enhanced testability

See [EVALU8_AUDIT.md](../Factor/EVALU8_AUDIT.md) for migration details.

## Development

### Key Components

- **DataStore**: Core Data stack manager (replaces PersistenceController)
- **Decision**: Main entity (renamed from DecisionCategory)
- **Option**: Decision option (renamed from DecisionOption)
- **ShareService**: CloudKit sharing operations (refactored from ShareManager)

### Testing

Run tests with ⌘U or use the Test Navigator in Xcode.

## CloudKit Configuration

The app uses CloudKit for data synchronization and sharing:
- Container: `iCloud.com.nollis.evalu8`
- Database Scope: Private
- Sync: Automatic via NSPersistentCloudKitContainer

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]

