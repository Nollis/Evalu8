# Evalu8 Project Setup Guide

## Step-by-Step Xcode Project Creation

### 1. Create New Xcode Project

1. Open Xcode
2. File → New → Project
3. Select **iOS** → **App**
4. Click **Next**
5. Fill in:
   - **Product Name**: `Evalu8`
   - **Team**: Select your team
   - **Organization Identifier**: `com.nollis`
   - **Bundle Identifier**: `com.nollis.evalu8`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: Core Data ✅
   - **Include Tests**: ✅
6. Click **Next**
7. Choose location: `C:\Swift\Evalu8` (or create new folder)
8. Click **Create**

### 2. Delete Default Files

Delete the default files Xcode created:
- `ContentView.swift` (we have our own)
- `Evalu8App.swift` (we have our own)
- `Evalu8.xcdatamodeld` (we have our own)

### 3. Add Project Files

1. In Xcode, right-click on the project root
2. Select **Add Files to "Evalu8"...**
3. Navigate to `C:\Swift\Evalu8`
4. Select all folders:
   - `Domain/`
   - `Data/`
   - `Presentation/`
   - `Supporting/`
   - `App/`
   - `Resources/`
   - `Tests/`
   - `UITests/`
5. Ensure **"Create groups"** is selected
6. Ensure **"Copy items if needed"** is NOT selected (files are already in place)
7. Click **Add**

### 4. Configure Core Data Model

1. Select `Evalu8.xcdatamodeld` in the project navigator
2. In the File Inspector, ensure:
   - **Codegen**: Class Definition
   - **Used with CloudKit**: ✅

### 5. Configure CloudKit

1. Select the **Evalu8** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **CloudKit**
5. In CloudKit configuration:
   - Container: `iCloud.com.nollis.evalu8`
   - Or click **+** to create new container with that identifier

### 6. Configure Info.plist

1. Select `Info.plist`
2. Ensure minimum iOS version is set to 17.0
3. Add URL schemes if needed for deep linking:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>evalu8</string>
           </array>
       </dict>
   </array>
   ```
4. Add permissions for Quick Decision feature (speech recognition and microphone):
   ```xml
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>We need speech recognition to convert your voice input into text for quick decision creation.</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>We need microphone access to record your voice for quick decision creation.</string>
   ```

### 7. Configure Build Settings

1. Select the **Evalu8** target
2. Go to **Build Settings**
3. Search for **iOS Deployment Target**
4. Set to **17.0**

### 8. Fix Import Issues

The project may have some import issues initially. Fix them:

1. Ensure all Swift files are added to the target
2. Check that `Evalu8.xcdatamodeld` is in the target
3. Build the project (⌘B) and fix any errors

### 9. Create Entitlements File

1. File → New → File
2. Select **Property List**
3. Name it `Evalu8.entitlements`
4. Add CloudKit container:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>com.apple.developer.icloud-container-identifiers</key>
       <array>
           <string>iCloud.com.nollis.evalu8</string>
       </array>
       <key>com.apple.developer.icloud-services</key>
       <array>
           <string>CloudKit</string>
       </array>
   </dict>
   </plist>
   ```

### 10. Build and Run

1. Select a simulator or device
2. Build (⌘B)
3. Run (⌘R)

## Troubleshooting

### Core Data Model Not Found
- Ensure `Evalu8.xcdatamodeld` is added to the target
- Check that the model file is in the correct location

### CloudKit Errors
- Verify CloudKit capability is added
- Check container identifier matches: `iCloud.com.nollis.evalu8`
- Ensure you're signed in with an Apple ID that has CloudKit access

### Import Errors
- Ensure all files are added to the target
- Check that file groups are properly organized
- Clean build folder (⌘ShiftK) and rebuild

### Missing Assets
- Verify `Assets.xcassets` is copied and added to target
- Check asset catalog is included in build phases

## Next Steps After Setup

1. Review the architecture: `EVALU8_ARCHITECTURE.md`
2. Check migration status: `MIGRATION_SUMMARY.md`
3. Review audit: `C:\Swift\Factor\EVALU8_AUDIT.md`
4. Start implementing remaining features

## Development Workflow

1. **Domain First**: Implement domain models and business logic
2. **Data Layer**: Implement repositories and data access
3. **Presentation**: Build views and view models
4. **Test**: Add tests as you build
5. **Refine**: Polish and optimize

## Resources

- Architecture: `EVALU8_ARCHITECTURE.md`
- Migration Summary: `MIGRATION_SUMMARY.md`
- Factor Audit: `C:\Swift\Factor\EVALU8_AUDIT.md`
- PRD: `C:\Swift\Factor\PRD.md`

