# XcodeGen Setup Guide

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`. This provides:

- ✅ Version-controlled project settings
- ✅ No merge conflicts in `.xcodeproj` files
- ✅ Reproducible builds
- ✅ Easier CI/CD setup
- ✅ Better team collaboration

## Installation

### Using Homebrew (Recommended)
```bash
brew install xcodegen
```

### Using Mint
```bash
mint install yonaskolb/xcodegen
```

### Using CocoaPods
Add to your `Podfile`:
```ruby
pod 'XcodeGen', '~> 2.0'
```

## Usage

### Generate Xcode Project

After installing XcodeGen, run:

```bash
xcodegen generate
```

This will create `Evalu8.xcodeproj` based on `project.yml`.

### Regenerate After Changes

Whenever you modify `project.yml`, regenerate the project:

```bash
xcodegen generate
```

**Note**: XcodeGen will preserve your manual changes to the project file, but regenerating will overwrite them. Always commit `project.yml` changes and regenerate rather than manually editing the `.xcodeproj`.

## Project Structure

The `project.yml` file defines:

- **Targets**: Evalu8 (main app), Evalu8Tests, Evalu8UITests
- **Sources**: All Swift files organized by layer (App, Domain, Data, Presentation, Supporting)
- **Resources**: Assets.xcassets
- **Capabilities**: CloudKit
- **Frameworks**: Speech, AVFoundation, CoreData, CloudKit
- **Settings**: Bundle ID, version, deployment target, Info.plist settings
- **Entitlements**: CloudKit container configuration

## Workflow

1. **Make changes to code** → Edit Swift files
2. **Update project.yml** → If adding new files/frameworks/capabilities
3. **Regenerate project** → `xcodegen generate`
4. **Open in Xcode** → `open Evalu8.xcodeproj`
5. **Build and run** → Standard Xcode workflow

## CI/CD Integration

In your CI/CD pipeline, you can generate the project:

```yaml
# Example GitHub Actions
- name: Generate Xcode Project
  run: |
    brew install xcodegen
    xcodegen generate
```

## Benefits

### Before XcodeGen
- ❌ `.xcodeproj` files cause merge conflicts
- ❌ Project settings scattered across Xcode UI
- ❌ Hard to reproduce exact project setup
- ❌ Difficult to version control project structure

### With XcodeGen
- ✅ `project.yml` is human-readable and version-controlled
- ✅ No merge conflicts (YAML is easier to merge)
- ✅ Reproducible builds across machines
- ✅ Easy to see all project settings in one place
- ✅ Can generate project in CI/CD

## Troubleshooting

### Project won't generate
- Check that `project.yml` is valid YAML
- Verify all file paths exist
- Check XcodeGen version: `xcodegen --version`

### Missing files after generation
- Ensure file paths in `project.yml` match actual file structure
- Check that files are in the correct directories
- Regenerate: `xcodegen generate`

### Build errors
- Clean build folder: `⌘ShiftK` in Xcode
- Regenerate project: `xcodegen generate`
- Rebuild: `⌘B`

## Updating project.yml

When adding new features:

1. **New Swift files**: Add to appropriate `sources` path
2. **New frameworks**: Add to `dependencies` section
3. **New capabilities**: Add to `capabilities` section
4. **New resources**: Add to `resources` section
5. **Regenerate**: `xcodegen generate`

## Example: Adding a New Framework

```yaml
dependencies:
  - framework: NewFramework.framework
    embed: false
```

Then regenerate: `xcodegen generate`

## References

- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)
- [XcodeGen Spec](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
- [Example project.yml files](https://github.com/yonaskolb/XcodeGen/tree/master/Examples)

---

**Note**: The generated `.xcodeproj` file is gitignored. Only `project.yml` is version controlled.

