# Google Cloud Setup Guide for Everyday-OS

This guide walks you through setting up Google Cloud services for use with N8N in Everyday-OS.

## Prerequisites

- A Google account
- Access to Google Cloud Console
- Your Everyday-OS instance deployed with N8N accessible at `https://n8n.yourdomain.com`

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click on the project dropdown at the top
3. Click "New Project"
4. Enter a project name (e.g., "Everyday-OS-Integration")
5. Note your **Project ID** - you'll need this later
6. Click "Create"

## Step 2: Enable Required APIs

Navigate to **APIs & Services → Library** and enable the following APIs based on your needs:

### Essential APIs for N8N:
- **Gmail API** - For email automation
- **Google Drive API** - For file storage and management
- **Google Sheets API** - For spreadsheet operations
- **Google Docs API** - For document creation and editing
- **Google Calendar API** - For calendar management

### Optional APIs:
- **Google Analytics API** - For analytics data
- **Google Ads API** - For advertising automation
- **YouTube Data API** - For YouTube operations
- **Google Cloud Vision API** - For image analysis
- **Google Cloud Natural Language API** - For text analysis

To enable each API:
1. Search for the API name
2. Click on the API
3. Click "Enable"
4. Wait for it to activate

## Step 3: Create OAuth 2.0 Credentials

1. Navigate to **APIs & Services → Credentials**
2. Click **"+ Create Credentials"** → **"OAuth client ID"**
3. If prompted, configure the OAuth consent screen first (see Step 4)
4. Select **Application type**: "Web application"
5. Enter a name (e.g., "N8N Integration")
6. Under **Authorized redirect URIs**, add:
   ```
   https://n8n.yourdomain.com/rest/oauth2-credential/callback
   ```
   Replace `yourdomain.com` with your actual domain
7. Click "Create"
8. **IMPORTANT**: Save the Client ID and Client Secret - you'll need these for N8N

## Step 4: Configure OAuth Consent Screen

If you haven't already configured the OAuth consent screen:

1. Go to **APIs & Services → OAuth consent screen**
2. Choose user type:
   - **Internal**: If using Google Workspace (recommended)
   - **External**: For personal Google accounts
3. Click "Create"
4. Fill in the required information:
   - App name: "Everyday-OS Integration"
   - User support email: Your email
   - App logo: Optional
   - App domain: Your domain (e.g., yourdomain.com)
   - Developer contact: Your email
5. Click "Save and Continue"

### Add Scopes:
1. Click "Add or Remove Scopes"
2. Add these essential scopes:
   https://www.googleapis.com/auth/userinfo.email
   https://www.googleapis.com/auth/userinfo.profile
   https://www.googleapis.com/auth/gmail.send
   https://www.googleapis.com/auth/gmail.readonly
   https://www.googleapis.com/auth/drive
   https://www.googleapis.com/auth/spreadsheets
   https://www.googleapis.com/auth/documents
   https://www.googleapis.com/auth/calendar
3. Add any additional scopes based on your needs
4. Click "Update" and "Save and Continue"

### Add Test Users (if External):
1. Add your email and any team members who need access
2. Click "Save and Continue"

## Step 5: Configure N8N Google Credentials

1. Log into N8N at `https://n8n.yourdomain.com`
2. Go to **Credentials** → **New**
3. Search for and select "Google OAuth2 API"
4. Enter your credentials:
   - **Client ID**: From Step 3
   - **Client Secret**: From Step 3
5. Click "Connect My Account"
6. You'll be redirected to Google to authorize
7. Grant the requested permissions
8. You'll be redirected back to N8N
9. Save the credential

## Step 6: (Optional) Create Service Account for Automation

If you want to use the Google Cloud automation script:

1. Go to **IAM & Admin → Service Accounts**
2. Click "Create Service Account"
3. Enter details:
   - Name: "Everyday-OS Automation"
   - Description: "Service account for automated Google Cloud setup"
4. Click "Create and Continue"
5. Grant roles:
   - **Project → Owner** (for full automation)
   - Or specific roles like "Project Editor" + "Service Usage Admin"
6. Click "Continue" and "Done"
7. Click on the service account email
8. Go to **Keys** tab
9. Click "Add Key" → "Create new key"
10. Choose "JSON" and click "Create"
11. Save the downloaded JSON file securely

### Configure Service Account in Everyday-OS:
1. Copy the entire JSON content
2. Add to your `.env` file:
   ```bash
   GOOGLE_SERVICE_ACCOUNT_KEY='{"type":"service_account",...}'
   ```

## Step 7: Testing Your Setup

### Test in N8N:
1. Create a new workflow
2. Add a Google node (e.g., Google Sheets)
3. Select your saved credential
4. Try a simple operation like "Get All Sheets"
5. If successful, your integration is working!

### Common Issues:

**"Access blocked" error:**
- Make sure you've added the redirect URI exactly as shown
- Check that all required APIs are enabled
- Verify your OAuth consent screen is configured

**"Insufficient permissions" error:**
- Add the required scopes in OAuth consent screen
- Re-authenticate in N8N to apply new scopes

**"API not enabled" error:**
- Go back to Step 2 and enable the specific API

## Security Best Practices

1. **Limit Scopes**: Only request the permissions you actually need
2. **Use Service Accounts Carefully**: They have programmatic access to your resources
3. **Rotate Credentials**: Periodically regenerate your OAuth credentials
4. **Monitor Usage**: Check API usage in Google Cloud Console regularly
5. **Set Quotas**: Configure API quotas to prevent unexpected usage

## Next Steps

- Set up workflows in N8N using Google services
- Explore the Google Cloud automation script for client onboarding
- Configure additional Google services as needed

For more information:
- [N8N Google Credentials Documentation](https://docs.n8n.io/integrations/builtin/credentials/google/)
- [Google Cloud API Documentation](https://cloud.google.com/apis/docs/overview)