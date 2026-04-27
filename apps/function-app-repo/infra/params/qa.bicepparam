using '../main.bicep'

// ─── Required: environment-specific values only ───
param environment = 'qa'
param appServicePlanId = '<qa-app-service-plan-resource-id>'
param storageAccountName = '<qa-storage-account-name>'

// ─── Optional overrides (uncomment only if QA differs from defaults in main.bicep) ───
// param appInsightsConnectionString = '<qa-app-insights-connection-string>'
// param vnetSubnetId = '<qa-subnet-resource-id>'
// param appSettings = []
