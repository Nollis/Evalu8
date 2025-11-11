# Quick Decision Feature

## Overview

The Quick Decision feature allows users to create decisions quickly using natural language input (text or voice). The app automatically:
- Parses the query to understand what decision is being made
- Generates relevant options (e.g., popular putter models)
- Creates appropriate criteria with weights
- Sets up the complete decision structure

## Usage

### Accessing Quick Decision

1. Open the Decisions list view
2. Tap the **sparkles icon** (✨) in the navigation bar
3. Enter your query or use voice input

### Example Queries

- "I am planning on buying a putter. Can you give me some choices?"
- "I need to choose a car"
- "Looking for a new phone"
- "Deciding on a restaurant for dinner"

### Voice Input

1. Tap the **"Use Voice"** button
2. Speak your query clearly
3. The app will transcribe your speech
4. Tap **"Generate Decision"** to create the decision

## How It Works

### 1. Query Parsing

The `AIService` parses natural language queries to extract:
- Decision type (e.g., "putter", "car", "phone")
- Context and description
- Title generation

### 2. Option Generation

Based on the decision type, the service generates relevant options:
- **Putter**: Odyssey White Hot OG, Scotty Cameron Select, TaylorMade Spider, etc.
- **Car**: Toyota Camry, Honda Accord, Tesla Model 3, etc.
- **Phone**: iPhone 15 Pro, Samsung Galaxy S24, Google Pixel 8, etc.
- And many more product categories

### 3. Criteria Generation

Automatically creates weighted criteria appropriate for the decision type:
- **Putter**: Feel and Balance (5), Price (4), Brand Reputation (3), etc.
- **Car**: Price (5), Fuel Efficiency (4), Safety Features (5), etc.
- Criteria weights are adjusted based on query context (e.g., "budget" increases price weight)

### 4. Decision Creation

Once generated, the user can:
- Preview the decision structure
- See all options and criteria
- Create the decision with one tap
- Start rating immediately

## Technical Implementation

### Components

1. **QuickDecisionSetup** (`Supporting/Models/QuickDecisionSetup.swift`)
   - Data structure for generated decision setup

2. **AIService** (`Supporting/Utilities/AIService.swift`)
   - `generateQuickDecision(from:)` - Main generation method
   - Query parsing with regex patterns
   - Option and criteria generation

3. **SpeechRecognizer** (`Supporting/Utilities/SpeechRecognizer.swift`)
   - Speech-to-text conversion
   - Real-time transcription
   - Permission handling

4. **QuickDecisionView** (`Presentation/Views/Decisions/QuickDecisionView.swift`)
   - UI for input and preview
   - Voice input integration
   - Generation status display

5. **DecisionListViewModel** (`Presentation/ViewModels/DecisionListViewModel.swift`)
   - `createQuickDecision(setup:)` - Creates decision with options and criteria

## Permissions Required

### Speech Recognition
Add to `Info.plist`:
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to convert your voice input into text for quick decision creation.</string>
```

### Microphone
Add to `Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record your voice for quick decision creation.</string>
```

## Future Enhancements

- Integration with real AI APIs (OpenAI, etc.) for better generation
- Learning from user preferences
- Custom option sources (web scraping, APIs)
- Multi-language support
- Improved query understanding with NLP
- Context-aware suggestions based on user history

## Example Flow

1. User: "I'm planning on buying a putter. Can you give me some choices?"
2. App parses: Decision type = "putter"
3. App generates:
   - Title: "Best Putter"
   - Options: 5 popular putter models
   - Criteria: 5 weighted criteria (Feel, Price, Brand, etc.)
4. User reviews preview
5. User taps "Create Decision"
6. Decision is created with all options and criteria ready for rating

---

**Note**: Currently uses local rule-based generation. Can be enhanced with real AI APIs for more sophisticated understanding and generation.

