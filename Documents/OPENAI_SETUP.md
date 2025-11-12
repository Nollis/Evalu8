# OpenAI API Setup Guide

## Overview

The Evalu8 app can use OpenAI's API to generate intelligent decision setups from natural language queries. This enables the app to handle any type of comparison query, not just predefined categories.

## Features

- **Intelligent Parsing**: Understands any natural language query
- **Context-Aware**: Generates relevant options and criteria based on the query
- **Automatic Weighting**: Assigns appropriate weights to criteria
- **Fallback Support**: Works without API key using local pattern matching

## Setup Instructions

### Option 1: Environment Variable (Recommended for Development)

1. Set the `OPENAI_API_KEY` environment variable in Xcode:
   - Product → Scheme → Edit Scheme
   - Run → Arguments → Environment Variables
   - Add: `OPENAI_API_KEY` = `your-api-key-here`

### Option 2: Info.plist (For Testing)

1. Add to `Info.plist`:
```xml
<key>OpenAIAPIKey</key>
<string>your-api-key-here</string>
```

**Note**: This is NOT secure for production. Use environment variables or a secure key management service.

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

