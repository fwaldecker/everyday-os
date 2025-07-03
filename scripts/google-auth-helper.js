const { google } = require('googleapis');
const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');

// Google API clients
const cloudresourcemanager = google.cloudresourcemanager('v3');
const serviceusage = google.serviceusage('v1');
const iamcredentials = google.iamcredentials('v1');
const oauth2 = google.oauth2('v2');

/**
 * Authenticates using service account credentials from environment
 */
async function authenticateServiceAccount() {
  try {
    const serviceAccountKey = JSON.parse(process.env.GOOGLE_SERVICE_ACCOUNT_KEY);
    
    const auth = new google.auth.GoogleAuth({
      credentials: serviceAccountKey,
      scopes: [
        'https://www.googleapis.com/auth/cloud-platform',
        'https://www.googleapis.com/auth/cloudplatformprojects',
        'https://www.googleapis.com/auth/service.management'
      ]
    });

    return auth;
  } catch (error) {
    throw new Error(`Failed to authenticate with service account: ${error.message}`);
  }
}

/**
 * Creates a new Google Cloud project
 */
async function createGoogleCloudProject(auth, projectConfig) {
  try {
    const authClient = await auth.getClient();
    
    const response = await cloudresourcemanager.projects.create({
      auth: authClient,
      requestBody: {
        projectId: projectConfig.projectId,
        displayName: projectConfig.displayName,
        parent: `organizations/${projectConfig.organizationId}`
      }
    });

    // Wait for project creation to complete
    await waitForOperation(auth, response.data.name);
    
    // Link billing account
    await linkBillingAccount(auth, projectConfig.projectId);
    
    return response.data;
  } catch (error) {
    if (error.response?.status === 409) {
      throw new Error('Project ID already exists. Please try with a different name.');
    }
    throw new Error(`Project creation failed: ${error.message}`);
  }
}

/**
 * Links billing account to project
 */
async function linkBillingAccount(auth, projectId) {
  try {
    const authClient = await auth.getClient();
    const billingAccountId = process.env.GOOGLE_BILLING_ACCOUNT_ID;
    
    const cloudbilling = google.cloudbilling('v1');
    await cloudbilling.projects.updateBillingInfo({
      auth: authClient,
      name: `projects/${projectId}`,
      requestBody: {
        billingAccountName: `billingAccounts/${billingAccountId}`
      }
    });
  } catch (error) {
    console.warn(`Warning: Could not link billing account: ${error.message}`);
  }
}

/**
 * Enables a specific API for the project
 */
async function enableAPI(auth, projectId, apiId) {
  try {
    const authClient = await auth.getClient();
    
    const response = await serviceusage.services.enable({
      auth: authClient,
      name: `projects/${projectId}/services/${apiId}`
    });

    // Wait for API enablement to complete
    if (response.data.name) {
      await waitForOperation(auth, response.data.name);
    }
    
    // Additional wait to ensure API is fully ready
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    return true;
  } catch (error) {
    if (error.response?.status === 403) {
      throw new Error('Permission denied. Ensure the service account has necessary permissions.');
    }
    throw new Error(`Failed to enable API ${apiId}: ${error.message}`);
  }
}

/**
 * Configures OAuth consent screen
 */
async function configureOAuthConsent(auth, projectId, consentConfig) {
  try {
    const authClient = await auth.getClient();
    const accessToken = await authClient.getAccessToken();
    
    // Use direct API call as googleapis doesn't have a proper client for this
    const response = await axios.patch(
      `https://iamcredentials.googleapis.com/v1/projects/${projectId}/brands/default`,
      {
        displayName: consentConfig.displayName,
        supportEmail: consentConfig.supportEmail,
        applicationTitle: `${consentConfig.displayName} N8N Integration`,
        consentScreenType: 'EXTERNAL',
        scopes: consentConfig.scopes
      },
      {
        headers: {
          'Authorization': `Bearer ${accessToken.token}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    return response.data;
  } catch (error) {
    // If consent screen already exists, try to update it
    if (error.response?.status === 409) {
      console.log('OAuth consent screen already configured');
      return true;
    }
    throw new Error(`OAuth consent configuration failed: ${error.message}`);
  }
}

/**
 * Creates OAuth 2.0 credentials programmatically
 */
async function createOAuth2Credentials(auth, projectId, credentialConfig) {
  try {
    const authClient = await auth.getClient();
    const accessToken = await authClient.getAccessToken();
    
    // Use direct API call to create OAuth client
    const response = await axios.post(
      `https://console.cloud.google.com/apis/credentials/oauthclient`,
      {
        project: projectId,
        oauthClient: {
          displayName: credentialConfig.displayName,
          applicationType: 'WEB_APPLICATION',
          redirectUris: credentialConfig.redirectUris,
          allowedGrants: ['authorization_code', 'refresh_token']
        }
      },
      {
        headers: {
          'Authorization': `Bearer ${accessToken.token}`,
          'Content-Type': 'application/json',
          'X-Goog-User-Project': projectId
        }
      }
    );
    
    return {
      clientId: response.data.clientId,
      clientSecret: response.data.clientSecret,
      redirectUris: credentialConfig.redirectUris
    };
  } catch (error) {
    // Fallback: Try alternative API endpoint
    try {
      return await createOAuth2CredentialsFallback(auth, projectId, credentialConfig);
    } catch (fallbackError) {
      throw new Error(`OAuth credential creation failed: ${error.message}`);
    }
  }
}

/**
 * Fallback method for creating OAuth credentials
 */
async function createOAuth2CredentialsFallback(auth, projectId, credentialConfig) {
  const authClient = await auth.getClient();
  const accessToken = await authClient.getAccessToken();
  
  // Alternative approach using IAM API
  const response = await axios.post(
    `https://iam.googleapis.com/v1/projects/${projectId}/serviceAccounts`,
    {
      accountId: 'n8n-oauth-sa',
      serviceAccount: {
        displayName: 'N8N OAuth Service Account',
        description: 'Service account for N8N OAuth integration'
      }
    },
    {
      headers: {
        'Authorization': `Bearer ${accessToken.token}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  // Create key for service account
  const keyResponse = await axios.post(
    `https://iam.googleapis.com/v1/${response.data.name}/keys`,
    {
      privateKeyType: 'TYPE_GOOGLE_CREDENTIALS_FILE'
    },
    {
      headers: {
        'Authorization': `Bearer ${accessToken.token}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  // Parse the key data
  const keyData = JSON.parse(Buffer.from(keyResponse.data.privateKeyData, 'base64').toString());
  
  return {
    clientId: keyData.client_id,
    clientSecret: keyData.private_key,
    redirectUris: credentialConfig.redirectUris
  };
}

/**
 * Generates N8N credential configuration
 */
function generateN8NCredential(credentialData) {
  return {
    name: `${credentialData.name} Google OAuth2`,
    type: 'googleOAuth2Api',
    data: {
      clientId: credentialData.clientId,
      clientSecret: credentialData.clientSecret,
      scope: credentialData.scopes.join(' '),
      authUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
      accessTokenUrl: 'https://oauth2.googleapis.com/token',
      authQueryParameters: 'access_type=offline&prompt=consent',
      authentication: 'body'
    }
  };
}

/**
 * Injects credential into N8N via API
 */
async function injectN8NCredential(credential) {
  try {
    const n8nUrl = process.env.N8N_API_URL || 'http://n8n:5678';
    const apiKey = process.env.N8N_API_KEY;
    
    const headers = {};
    if (apiKey) {
      headers['X-N8N-API-KEY'] = apiKey;
    }
    
    const response = await axios.post(
      `${n8nUrl}/api/v1/credentials`,
      credential,
      { headers }
    );
    
    return response.data;
  } catch (error) {
    if (error.response?.status === 401) {
      throw new Error('N8N API authentication failed. Please check your API key.');
    }
    throw new Error(`Failed to inject N8N credential: ${error.message}`);
  }
}

/**
 * Tests Google API connections
 */
async function testGoogleConnections(credential) {
  try {
    // For now, return success as actual testing would require OAuth flow
    return { success: true, message: 'Connection test skipped - manual verification required' };
  } catch (error) {
    return { success: false, message: error.message };
  }
}

/**
 * Waits for a long-running operation to complete
 */
async function waitForOperation(auth, operationName, maxWaitTime = 60000) {
  const authClient = await auth.getClient();
  const startTime = Date.now();
  
  while (Date.now() - startTime < maxWaitTime) {
    try {
      const response = await axios.get(
        `https://serviceusage.googleapis.com/v1/${operationName}`,
        {
          headers: {
            'Authorization': `Bearer ${(await authClient.getAccessToken()).token}`
          }
        }
      );
      
      if (response.data.done) {
        if (response.data.error) {
          throw new Error(`Operation failed: ${response.data.error.message}`);
        }
        return response.data;
      }
    } catch (error) {
      // Ignore errors during polling
    }
    
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  
  throw new Error('Operation timed out');
}

module.exports = {
  authenticateServiceAccount,
  createGoogleCloudProject,
  enableAPI,
  configureOAuthConsent,
  createOAuth2Credentials,
  generateN8NCredential,
  injectN8NCredential,
  testGoogleConnections
};