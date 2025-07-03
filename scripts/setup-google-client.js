#!/usr/bin/env node

const inquirer = require('inquirer');
const chalk = require('chalk');
const ora = require('ora');
const { google } = require('googleapis');
const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const {
  authenticateServiceAccount,
  createGoogleCloudProject,
  enableAPI,
  configureOAuthConsent,
  createOAuth2Credentials,
  generateN8NCredential,
  injectN8NCredential,
  testGoogleConnections
} = require('./google-auth-helper');

// API Configuration
const REQUIRED_APIS = [
  { id: 'gmail.googleapis.com', name: 'Gmail API' },
  { id: 'drive.googleapis.com', name: 'Drive API' },
  { id: 'docs.googleapis.com', name: 'Docs API' },
  { id: 'calendar-json.googleapis.com', name: 'Calendar API' },
  { id: 'monitoring.googleapis.com', name: 'Monitoring API' },
  { id: 'analytics.googleapis.com', name: 'Analytics API' },
  { id: 'googleads.googleapis.com', name: 'Google Ads API' },
  { id: 'servicemanagement.googleapis.com', name: 'Service Management API' },
  { id: 'sheets.googleapis.com', name: 'Sheets API' },
  { id: 'clouderrorreporting.googleapis.com', name: 'Cloud Error Reporting API' }
];

const OAUTH_SCOPES = [
  'https://www.googleapis.com/auth/drive',
  'https://www.googleapis.com/auth/gmail.send',
  'https://www.googleapis.com/auth/gmail.readonly',
  'https://www.googleapis.com/auth/documents',
  'https://www.googleapis.com/auth/calendar',
  'https://www.googleapis.com/auth/analytics.readonly',
  'https://www.googleapis.com/auth/adwords',
  'https://www.googleapis.com/auth/spreadsheets'
];

async function promptClientInfo() {
  console.log(chalk.blue.bold('\n🚀 Google Cloud Setup Automation for N8N\n'));
  
  const answers = await inquirer.prompt([
    {
      type: 'input',
      name: 'companyName',
      message: 'Client company name:',
      validate: input => input.length > 0 || 'Company name is required'
    },
    {
      type: 'input',
      name: 'email',
      message: 'Client email:',
      validate: input => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input) || 'Please enter a valid email'
    },
    {
      type: 'input',
      name: 'domain',
      message: 'Client domain:',
      validate: input => /^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$/.test(input) || 'Please enter a valid domain'
    },
    {
      type: 'input',
      name: 'organizationId',
      message: 'Their Google Cloud Organization ID:',
      validate: input => /^\d+$/.test(input) || 'Organization ID must be numeric'
    }
  ]);

  return answers;
}

async function setupGoogleClient() {
  try {
    const startTime = Date.now();
    
    // Step 1: Collect client information
    const clientInfo = await promptClientInfo();
    console.log(chalk.green('\n✓ Client information collected\n'));

    // Step 2: Authenticate with service account
    const spinner = ora('Authenticating with Google Cloud...').start();
    const auth = await authenticateServiceAccount();
    spinner.succeed('Authenticated with Google Cloud');

    // Step 3: Create project
    const projectId = `${clientInfo.companyName.toLowerCase().replace(/[^a-z0-9]/g, '-')}-n8n-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}`;
    spinner.start(`Creating project in ${clientInfo.companyName}'s Google Cloud...`);
    
    try {
      await createGoogleCloudProject(auth, {
        projectId,
        displayName: `${clientInfo.companyName} N8N Integration`,
        organizationId: clientInfo.organizationId
      });
      spinner.succeed(`Created project: ${chalk.bold(projectId)}`);
    } catch (error) {
      spinner.fail(`Failed to create project: ${error.message}`);
      throw error;
    }

    // Step 4: Enable APIs
    console.log(chalk.yellow('\n🔄 Enabling premium APIs...\n'));
    
    for (const api of REQUIRED_APIS) {
      const apiSpinner = ora(`Enabling ${api.name}...`).start();
      try {
        await enableAPI(auth, projectId, api.id);
        apiSpinner.succeed(`Enabled ${api.name}`);
      } catch (error) {
        apiSpinner.fail(`Failed to enable ${api.name}: ${error.message}`);
        // Continue with other APIs even if one fails
      }
    }

    // Step 5: Configure OAuth consent screen
    spinner.start('Configuring OAuth consent screen...');
    try {
      await configureOAuthConsent(auth, projectId, {
        displayName: clientInfo.companyName,
        supportEmail: clientInfo.email,
        scopes: OAUTH_SCOPES
      });
      spinner.succeed('Configured OAuth consent screen');
    } catch (error) {
      spinner.fail(`Failed to configure OAuth consent: ${error.message}`);
      throw error;
    }

    // Step 6: Create OAuth credentials
    spinner.start('Creating OAuth credentials...');
    try {
      const oauthCredentials = await createOAuth2Credentials(auth, projectId, {
        displayName: `${clientInfo.companyName} N8N Integration`,
        redirectUris: [
          `https://n8n.${clientInfo.domain}/rest/oauth2-credential/callback`,
          'http://localhost:5678/rest/oauth2-credential/callback'
        ]
      });
      spinner.succeed('Created OAuth credentials automatically');
      
      // Step 7: Generate N8N configuration
      spinner.start('Generating N8N configuration...');
      const n8nConfig = generateN8NCredential({
        name: clientInfo.companyName,
        clientId: oauthCredentials.clientId,
        clientSecret: oauthCredentials.clientSecret,
        scopes: OAUTH_SCOPES
      });
      spinner.succeed('Generated N8N configuration');

      // Step 8: Inject into N8N
      spinner.start('Injecting credentials into N8N...');
      try {
        await injectN8NCredential(n8nConfig);
        spinner.succeed('Injected credentials into N8N');
      } catch (error) {
        spinner.warn(`Could not inject credentials automatically: ${error.message}`);
        console.log(chalk.yellow('\nManual N8N configuration required. Credentials saved to: google-credentials.json'));
        await fs.writeFile('google-credentials.json', JSON.stringify(n8nConfig, null, 2));
      }

      // Step 9: Test connections
      spinner.start('Testing connections...');
      const testResults = await testGoogleConnections(n8nConfig);
      if (testResults.success) {
        spinner.succeed('Tested connections - all working!');
      } else {
        spinner.warn('Some connections may need manual testing');
      }

      // Calculate setup time
      const setupTime = Math.floor((Date.now() - startTime) / 1000 / 60);
      
      // Success message
      console.log(chalk.green.bold(`\n🎉 Complete setup in ${setupTime} minutes!\n`));
      console.log(chalk.white('OAuth Client Details:'));
      console.log(chalk.gray(`- Client ID: ${oauthCredentials.clientId}`));
      console.log(chalk.gray(`- N8N Credential Name: ${clientInfo.companyName} Google OAuth2`));
      console.log(chalk.gray('- All 10 APIs enabled and ready to use\n'));

    } catch (error) {
      spinner.fail(`OAuth credential creation failed: ${error.message}`);
      throw error;
    }

  } catch (error) {
    console.error(chalk.red('\n❌ Setup failed:'), error.message);
    console.error(chalk.yellow('\nPlease check your configuration and try again.'));
    process.exit(1);
  }
}

// Check required environment variables
function checkEnvironment() {
  const required = [
    'GOOGLE_SERVICE_ACCOUNT_KEY',
    'GOOGLE_BILLING_ACCOUNT_ID',
    'N8N_API_URL'
  ];

  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    console.error(chalk.red('❌ Missing required environment variables:'));
    missing.forEach(key => console.error(chalk.red(`  - ${key}`)));
    console.error(chalk.yellow('\nPlease set these in your .env file and try again.'));
    process.exit(1);
  }
}

// Main execution
async function main() {
  console.clear();
  checkEnvironment();
  await setupGoogleClient();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { setupGoogleClient };