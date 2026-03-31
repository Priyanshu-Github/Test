using '../main.bicep'

param environment = 'uat'
param location = 'eastus2'
param appName = 'func-new-watcher'
param appServicePlanId = '<uat-app-service-plan-resource-id>'
param storageAccountName = 'stnewwatcheruat'
param appInsightsConnectionString = '<uat-app-insights-connection-string>'
param functionsWorkerRuntime = 'python'
param linuxFxVersion = 'Python|3.11'
param tags = {
  project: 'ml-platform'
  team: 'platform'
}
