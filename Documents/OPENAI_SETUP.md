# OpenAI API Setup Guide

## Overview

The Evalu8 app can use OpenAI's API to generate intelligent decision setups from natural language queries. This enables the app to handle any type of comparison query, not just predefined categories.

## Features

- **Intelligent Parsing**: Understands any natural language query
- **Context-Aware**: Generates relevant options and criteria based on the query
- **Automatic Weighting**: Assigns appropriate weights to criteria
- **Fallback Support**: Works without API key using local pattern matching

## Setup Instructions

### ⚠️ Important: Git Pull Issue

**If you put your API key in `Info.plist`, it will be overwritten every time you pull from git!**

The `Info.plist` file is tracked in git, so any changes you make locally will be lost when you pull updates.

### Option 1: Environment Variable (✅ Recommended - Won't be lost on git pull)

**This is the recommended approach** because:
- ✅ Your API key won't be overwritten on git pull
- ✅ Each developer can use their own key
- ✅ More secure (not committed to git)

**Steps:**
1. Open Xcode
2. Click on the **Evalu8** scheme dropdown (next to the play/stop buttons)
3. Select **Edit Scheme...**
4. In the left sidebar, select **Run**
5. Click the **Arguments** tab
6. Under **Environment Variables**, click the **+** button
7. Add:
   - **Name**: `OPENAI_API_KEY`
   - **Value**: `your-actual-api-key-here`
8. Click **Close**

**To find Info.plist in Xcode:**
- In the Project Navigator (left sidebar), look for `Info.plist` at the root level
- Or: Select the **Evalu8** target → **Info** tab → Custom iOS Target Properties

### Option 2: Info.plist (⚠️ Not Recommended - Will be lost on git pull)

1. Open `Info.plist` in Xcode (see above for location)
2. Find the `OpenAIAPIKey` key (it should have `YOUR_OPENAI_API_KEY_HERE` as value)
3. Replace `YOUR_OPENAI_API_KEY_HERE` with your actual API key

**Warning**: This value will be overwritten every time you run `git pull`!

### Option 3: Secure Key Storage (Production)

For production apps, consider:
- Using a backend service to proxy API calls
- Using iOS Keychain for secure storage
- Using a configuration service

## Getting an OpenAI API Key

1. Go to https://platform.openai.com/
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new secret key
5. Copy the key (you won't be able to see it again)

**Important:** OpenAI API keys start with `sk-` or `sk-proj-`. If your key starts with something else (like `ghp_` for GitHub tokens), it won't work!

## Cost Considerations

The app uses `gpt-4o-mini` model which is cost-effective:
- ~$0.15 per 1M input tokens
- ~$0.60 per 1M output tokens
- Typical query: ~500 tokens input, ~200 tokens output
- Estimated cost: ~$0.0002 per query

## Usage

Once configured, the app will automatically use OpenAI for:
- Generating options from any query
- Creating relevant criteria with weights
- Understanding context and intent

### Example Queries

- "I want to compare golf putters"
- "Help me decide between job offers"
- "What's the best restaurant for a date?"
- "Compare different programming languages"
- "I need to choose a vacation destination"

## Fallback Behavior

If OpenAI API is not configured or fails:
- App falls back to local pattern matching
- Works for common categories (putters, cars, phones, etc.)
- May not work for creative/unusual queries

## Troubleshooting

### API Key Not Working
- Verify the key is correct
- Check API key has sufficient credits
- Ensure network connectivity
- Check Xcode console for error messages

### Rate Limits
- OpenAI has rate limits based on your plan
- App will fall back to local generation if rate limited
- Consider implementing retry logic for production

## Security Best Practices

1. **Never commit API keys to git**
   - Add to `.gitignore`
   - Use environment variables
   - Use secure key storage

2. **Rotate keys regularly**
   - Change keys if compromised
   - Use different keys for dev/prod

3. **Monitor usage**
   - Set up billing alerts
   - Monitor API usage in OpenAI dashboard

## Future Enhancements

- Support for other AI providers (Anthropic, Google, etc.)
- On-device models for privacy
- Caching of common queries
- User preference learning

