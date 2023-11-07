####################
# Customer Tenant #
####################
## Warning This Script use the template for all the subscription with permanent right ##
## If you want to manage only a Resource Group or multiple resource group don't use this script ##
## Prerequisite ##
## A user with the Owner right of the Azure Tenant ##

##############
# Variables #
##############
$EndCustomerAzureSubscriptionName = "" ## Replace with the Endcustomer Azure Subscription Name ##
$Location = "westeurope" ## Replace by your Azure Region ##

##################################
# Connect to Azure and Azure AD #
##################################
Install-Module az -Force
Import-Module az -Force
Install-Module azuread -Force
Import-Module azuread -Force
Clear-AzContext
Connect-AzAccount
$EndCustomerSubscription = Get-AzSubscription -SubscriptionName $EndCustomerAzureSubscriptionName
$EndCustomerSubscriptionId = $EndCustomerSubscription.Id
Select-AzSubscription -SubscriptionId $EndCustomerSubscriptionId
$EndCustomerTenantId = $EndCustomerSubscription.TenantId
Connect-AzureAD -TenantId $EndCustomerTenantId

######################
# Register Provider #
######################
Register-AzResourceProvider -ProviderNamespace Microsoft.ManagedServices

#########################################################################################################################
# Deploy the Json Template that you previously download and modify the Lighthouse-Partner-Deployment Powershell Script #
#########################################################################################################################
$LigthousePartnerTemplateOutputFile = "C:\PartnerLighthouse\Lighthouse-partner-right.json"

New-AzSubscriptionDeployment -Name DeployServiceProviderTemplate `
-Location $Location `
-TemplateFile $LigthousePartnerTemplateOutputFile
-Verbose

#Confirm Successful Onboarding for Azure Lighthouse
Get-AzManagedServicesDefinition |fl
Get-AzManagedServicesAssignment |fl

#In about 15 minutes the MSP should be visible in the Customer Subscription
Start-Process "https://portal.azure.com/#blade/Microsoft_Azure_CustomerHub/ServiceProvidersBladeV2/providers"
