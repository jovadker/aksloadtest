param vnetName string
param virtualNetworkAddressPrefix string
param location string
param kubernetesSubnetName string
param aksSubnetAddressPrefix string
param applicationGatewaySubnetName string
param applicationGatewaySubnetAddressPrefix string

resource vnetNameResource 'Microsoft.Network/virtualNetworks@2018-08-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: kubernetesSubnetName
        properties: {
          addressPrefix: aksSubnetAddressPrefix
        }
      }
      {
        name: applicationGatewaySubnetName
        properties: {
          addressPrefix: applicationGatewaySubnetAddressPrefix
        }
      }
    ]
  }
}

output vnetid string = vnetNameResource.id
