using '../main.bicep'

// ─── Required: environment-specific values only ───
param environment = 'prod'
param appServicePlanId = '<prod-app-service-plan-resource-id>'
param storageAccountName = '<prod-storage-account-name>'

// ─── Optional overrides (uncomment only if Prod differs from defaults in main.bicep) ───
// param appInsightsConnectionString = '<prod-app-insights-connection-string>'
// param vnetSubnetId = '<prod-subnet-resource-id>'
// param appSettings = []
