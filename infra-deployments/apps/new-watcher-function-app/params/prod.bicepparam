using '../main.bicep'

param environment = 'prod'
param location = 'eastus2'
param appName = 'func-new-watcher'
param appServicePlanId = '<prod-app-service-plan-resource-id>'
param storageAccountName = 'stnewwatcherprod'
param appInsightsConnectionString = '<prod-app-insights-connection-string>'
param functionsWorkerRuntime = 'python'
param linuxFxVersion = 'Python|3.11'
param tags = {
  project: 'ml-platform'
  team: 'platform'
}
