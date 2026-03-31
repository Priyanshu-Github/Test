using '../main.bicep'

param environment = 'qa'
param location = 'eastus2'
param appName = 'func-new-watcher'
param appServicePlanId = '<qa-app-service-plan-resource-id>'
param storageAccountName = 'stnewwatcherqa'
param appInsightsConnectionString = '<qa-app-insights-connection-string>'
param functionsWorkerRuntime = 'python'
param linuxFxVersion = 'Python|3.11'
param tags = {
  project: 'ml-platform'
  team: 'platform'
}
