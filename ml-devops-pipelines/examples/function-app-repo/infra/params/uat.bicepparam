using '../main.bicep'

// ─── Required: environment-specific values only ───
param environment = 'uat'
param appServicePlanId = '<uat-app-service-plan-resource-id>'
param storageAccountName = '<uat-storage-account-name>'

// ─── Optional overrides (uncomment only if UAT differs from defaults in main.bicep) ───
// param appInsightsConnectionString = '<uat-app-insights-connection-string>'
// param vnetSubnetId = '<uat-subnet-resource-id>'
// param logAnalyticsWorkspaceId = '<uat-log-analytics-workspace-id>'
// param appSettings = []
