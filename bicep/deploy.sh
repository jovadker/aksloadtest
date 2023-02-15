resourceGroup=JMeterAKS.BICEP.RG
location=westeurope
containerRegistry=Bicepjovadker
containerRegistrySKU=Basic
AppGwPrefixName=vadkertibicep
deploymentName=20220824_1
grafanaAdminId=59a3a0c4-XXXX-XXXX-XXXX-XXXXXXXXXXXX

az group create --name $resourceGroup --location $location
az deployment group create --name $deploymentName -g $resourceGroup --debug --template-file ./main.bicep \
       --parameters acrName=$containerRegistry acrAdminUserEnabled=false acrSku=$containerRegistrySKU applicationGatewayDNSPrefixName=$AppGwPrefixName \
         grafanaAdminUserOrGroupID=$grafanaAdminId