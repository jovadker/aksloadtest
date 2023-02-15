@description('Containers DNS server IP address.')
param virtualNetworkAddressPrefix string = '10.0.0.0/8'

@description('Containers DNS server IP address.')
param aksSubnetAddressPrefix string = '10.0.0.0/16'

@description('Containers DNS server IP address.')
param applicationGatewaySubnetAddressPrefix string = '10.1.0.0/16'

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param aksDnsPrefix string = 'aks'

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 30 to 1023.')
@minValue(30)
@maxValue(1023)
param aksAgentOsDiskSizeGB int = 40

@description('The number of agent nodes for the cluster.')
@minValue(1)
@maxValue(5)
param aksAgentCount int = 3

@description('Min node number for auto scaling')
param aksAgentMinCount int = 1

@description('Min node number for auto scaling')
param aksAgentMaxCount int = 5

@description('Min node number for auto scaling')
param aksSystemAgentMinCount int = 1

@description('Min node number for auto scaling')
param aksSystemAgentMaxCount int = 5

@description('The size of the Virtual Machine.')
@allowed([
  'Standard_D8s_v4'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_D4s_v3'
  'Standard_DS5_v2'
  'Standard_D8s_v3'
  'Standard_D16s_v3'
  'Standard_D32s_v3'
  'Standard_D48s_v3'
  'Standard_D64s_v3'
])
param aksAgentVMSize string = 'Standard_DS3_v2'

@description('The size of the Virtual Machine.')
param aksSystemAgentVMSize string = 'Standard_D2_v3'

@description('The number of agent nodes for the cluster.')
@minValue(1)
@maxValue(5)
param aksSystemAgentCount int = 3

@description('The version of Kubernetes.')
param kubernetesVersion string = '1.23.5'

@description('A CIDR notation IP range from which to assign service cluster IPs.')
param aksServiceCIDR string = '10.2.0.0/16'

@description('Containers DNS server IP address.')
param aksDnsServiceIP string = '10.2.0.10'

@description('A CIDR notation IP for Docker bridge.')
param aksDockerBridgeCIDR string = '172.17.0.1/16'

@description('Enable RBAC on the AKS cluster.')
param aksEnableRBAC bool = true

@description('The sku of the Application Gateway. Default: WAF_v2 (Detection mode). In order to further customize WAF, use azure portal or cli.')
@allowed([
  'Standard_v2'
  'WAF_v2'
])
param applicationGatewaySku string = 'WAF_v2'

@description('Name of your Azure Container Registry')
@minLength(5)
@maxLength(50)
param acrName string

@description('Enable admin user that have push / pull permission to the registry.')
param acrAdminUserEnabled bool = false

@description('Tier of your Azure Container Registry.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'
param applicationGatewayDNSPrefixName string

@description('Location of the resources')
param location string = resourceGroup().location

@description('The ID of the Azure Active Directory group or user that has admin rights to the Grafana instance.')
param grafanaAdminUserOrGroupID string

var resgpguid = substring(replace(guid(resourceGroup().id), '-', ''), 0, 4)
var applicationGatewayName_var = 'applicationgateway${resgpguid}'
var applicationGatewayPublicIpName_var = 'appgwpublicip${resgpguid}'
var kubernetesSubnetName = 'kubesubnet'
var applicationGatewaySubnetName = 'appgwsubnet'
var aksClusterName_var = 'aks${resgpguid}'
var vnetName_var = 'virtualnetwork${resgpguid}'
var applicationGatewayPublicIpId = applicationGatewayPublicIpName.id
var aksClusterId = aksClusterName.id
var contributorRole = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
var readerRole = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
var webApplicationFirewallConfiguration = {
  enabled: 'true'
  firewallMode: 'Detection'
}
var acrPullRoleDefinitionName = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var acrPullRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleDefinitionName)
var appInsightsName_var = 'appinsights${resgpguid}'
var workspaceName_var = 'workspace${resgpguid}'
var dashboardName_var = 'dashboard${resgpguid}'
var grafanaAdminRoleDefinitionName = '22926164-76b3-42b3-bc55-97df8dab3e41'
var grafanaAdminRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', grafanaAdminRoleDefinitionName)

resource acrName_resource 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  name: acrName
  location: location
  tags: {
    displayName: 'Container Registry'
    'container.registry': acrName
  }
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: acrAdminUserEnabled
  }
}

//consume virtual network as module
module vnetModule './modules/vnet.bicep' = {
  name:'vnetModule'
  params: {
    vnetName: vnetName_var
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    location: location
    kubernetesSubnetName: kubernetesSubnetName
    aksSubnetAddressPrefix: aksSubnetAddressPrefix
    applicationGatewaySubnetName: applicationGatewaySubnetName
    applicationGatewaySubnetAddressPrefix: applicationGatewaySubnetAddressPrefix
  }
}

resource applicationGatewayPublicIpName 'Microsoft.Network/publicIPAddresses@2018-08-01' = {
  name: applicationGatewayPublicIpName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: applicationGatewayDNSPrefixName
    }
  }
}

resource applicationGatewayName_resource 'Microsoft.Network/applicationGateways@2020-11-01' = {
  name: applicationGatewayName_var
  location: location
  tags: {
    'managed-by-k8s-ingress': 'true'
  }
  properties: {
    sku: {
      name: applicationGatewaySku
      tier: applicationGatewaySku
    }
    autoscaleConfiguration: {
      maxCapacity: 2
      minCapacity: 0
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, applicationGatewaySubnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: applicationGatewayPublicIpId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'httpPort'
        properties: {
          port: 80
        }
      }
      {
        name: 'httpsPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'bepool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener'
        properties: {
          protocol: 'Http'
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName_var, 'httpPort')
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName_var, 'appGatewayFrontendIP')
          }
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'setting'
        properties: {
          port: 80
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName_var, 'httpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName_var, 'bepool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName_var, 'setting')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: ((applicationGatewaySku == 'WAF_v2') ? webApplicationFirewallConfiguration : json('null'))
  }
}


resource applicationGatewayName_Microsoft_Authorization_id_identityappgwaccess 'Microsoft.Network/applicationgateways/providers/roleAssignments@2017-05-01' = {
  name: '${applicationGatewayName_var}/Microsoft.Authorization/${guid(resourceGroup().id, 'identityappgwaccess')}'
  properties: {
    roleDefinitionId: contributorRole
    principalId: reference(aksClusterId, '2020-12-01', 'Full').properties.addonProfiles.ingressApplicationGateway.identity.objectId
    scope: resourceId('Microsoft.Network/applicationGateways', applicationGatewayName_var)
  }
  dependsOn: [
   applicationGatewayName_resource
  ]
}

resource id_identityrgaccess 'Microsoft.Authorization/roleAssignments@2017-05-01' = {
  name: guid(resourceGroup().id, 'identityrgaccess')
  properties: {
    roleDefinitionId: readerRole
    principalId: reference(aksClusterId, '2020-12-01', 'Full').properties.addonProfiles.ingressApplicationGateway.identity.objectId
    scope: resourceGroup().id
  }
  dependsOn: [
    applicationGatewayName_resource
  ]
}

resource aksClusterName 'Microsoft.ContainerService/managedClusters@2021-09-01' = {
  name: aksClusterName_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: aksEnableRBAC
    dnsPrefix: aksDnsPrefix
    addonProfiles: {
      ingressApplicationGateway: {
        config: {
          applicationGatewayId: resourceId('Microsoft.Network/applicationGateways', applicationGatewayName_var)
        }
        enabled: true
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: workspaceName.id
        }
      }
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: aksAgentOsDiskSizeGB
        count: aksAgentCount
        vmSize: aksAgentVMSize
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        enableAutoScaling: true
        minCount: aksAgentMinCount
        maxCount: aksAgentMaxCount
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, kubernetesSubnetName)
        mode: 'User'
        nodeLabels: {
          environment: 'testpool'
        }
      }
      {
        name: 'systempool'
        osDiskSizeGB: aksAgentOsDiskSizeGB
        count: aksSystemAgentCount
        enableAutoScaling: true
        minCount: aksSystemAgentMinCount
        maxCount: aksSystemAgentMaxCount
        vmSize: aksSystemAgentVMSize
        osType: 'Linux'
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, kubernetesSubnetName)
        mode: 'System'
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: aksServiceCIDR
      dnsServiceIP: aksDnsServiceIP
      dockerBridgeCidr: aksDockerBridgeCIDR
      loadBalancerSku: 'Standard'
      outboundType: 'loadBalancer'
      loadBalancerProfile: {
        managedOutboundIPs: {
          count: 1
        }
      }
    }
  }
  dependsOn: [
    applicationGatewayName_resource
  ]
}

resource appInsightsName 'microsoft.insights/components@2020-02-02' = {
  name: appInsightsName_var
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: workspaceName.id
  }
}

resource id 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = { scope: acrName_resource, name: guid(resourceGroup().id), properties: {
    roleDefinitionId: acrPullRoleId
    principalId: reference(aksClusterId, '2020-12-01', 'Full').properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  } }

resource workspaceName 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: workspaceName_var
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
  }
}

resource dashboardName 'Microsoft.Dashboard/grafana@2021-09-01-preview' = {
  name: dashboardName_var
  location: location
  properties: {
    zoneRedundancy: 'Disabled'
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
  }
  sku: {
    name: 'Standard'
  }
  dependsOn: [
    aksClusterName
  ]
}

resource id_grafana 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: dashboardName
  name: guid(resourceGroup().id, 'grafana')
  properties: {
    roleDefinitionId: grafanaAdminRoleId
    principalId: grafanaAdminUserOrGroupID
  }
  dependsOn: [
    aksClusterName

  ]
}

resource id_systemassigned 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, 'systemassigned')
  properties: {
    roleDefinitionId: contributorRole
    principalId: reference(aksClusterId, '2020-12-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output subscriptionId string = subscription().subscriptionId
output resourceGroupName string = resourceGroup().name
output applicationGatewayName string = applicationGatewayName_var
output identityResourceId string = reference(aksClusterId, '2020-12-01', 'Full').properties.identityProfile.kubeletidentity.objectId
output identityClientId string = reference(aksClusterId, '2020-12-01', 'Full').properties.identityProfile.kubeletidentity.clientId
output aksApiServerAddress string = reference(aksClusterId, '2018-03-31').fqdn
output aksClusterName string = aksClusterName_var
output JMeterAppInsightsInstrumentationKey string = reference(appInsightsName.id, '2014-04-01').InstrumentationKey
