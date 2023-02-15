#!/usr/bin/env bash
#This script deploy AppGW Ingress controller to the specified aks cluster

subscriptionId=$0
$aksClusterName=$1
resourceGroupName=$2
applicationGatewayName=$3
identityResourceId=$4
identityClientId=$5


#Step1
az aks get-credentials --resource-group $resourceGroupName --name $aksClusterName

#Step2
helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
helm repo update

#Step3
wget https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/sample-helm-config.yaml -O helm-config.yaml

#Step4
sed -i "s|<subscriptionId>|${subscriptionId}|g" helm-config.yaml
sed -i "s|<resourceGroupName>|${resourceGroupName}|g" helm-config.yaml
sed -i "s|<applicationGatewayName>|${applicationGatewayName}|g" helm-config.yaml
sed -i "s|<identityResourceId>|${identityResourceId}|g" helm-config.yaml
sed -i "s|<identityClientId>|${identityClientId}|g" helm-config.yaml

#Step5
helm install ingress-azure \
  -f helm-config.yaml \
  application-gateway-kubernetes-ingress/ingress-azure \
  --version 1.2.0-rc3