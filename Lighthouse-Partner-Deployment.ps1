###################
# Partner Tenant #
###################
#Partner Side
#Warning This Script use the template for all the subscription with permanent right
#If you want to manage only a Resource Group or multiple resource group don't use this script
#Prerequisite
#A user with the Owner right of the Azure Tenant

##############
# Variables #
##############
$PartnerAzureSubscriptionName = "MSDN FR 2" # Replace with your Azure Subscription Name

## End Customer Name Used in the Entra Group ##
$EndcustomerName = "ABC" # Replace with your End Customer Name
## End Customer Name Used in the Entra Group ##

## Entra Group ##
$LighthouseAzureADGroupName  = "Lighthouse Management {0}" -f $EndcustomerName
$LighthouseAzureADGroupNickName = "Lighthouse"
$LighthouseAzureADGroupDescription = "This is your Lighthouse Group for the Administration of your customer $($EndcustomerName)"
## Entra Group ##

## Owner of the Entra Group ##
$LighthouseAzureADGroupOwner = "alex admin"  # Replace with the user's Display Name
## Owner of the Entra Group ##

## Member of the Entra Group ##
$LighthouseAzureADGroupMember = @("alexuser@demomsdnalex.onmicrosoft.com", "demo104@demomsdnalex.onmicrosoft.com", "jlo@DemoMSDNAlex.onmicrosoft.com")  # Add as many users as needed
## Member of the Entra Group ##

## Azure Ligthouse Variable ##
$PartnerName = "DCE" # Replace with your Name
$LighthouseOfferName = "Lighthouse access" -f $PartnerName
$LighthouseOfferDescription = "This is your Lighthouse Access of $($PartnerName) for the Administration of the tenant of Tenant"

########################################################
# Github repository where the script will be download #
########################################################
$PartnerLighthousegithubRawUrl = ""
$LigthousePartnerTemplateOutputFile = "C:\PartnerLighthouse\Lighthouse-partner-right.json"

##########################
# Create Temp Directory #
##########################
$folderPath = "C:\PartnerLighthouse"

if (-not (Test-Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath
    Write-Host "Folder created: $folderPath"
} else {
    Write-Host "Folder already exists: $folderPath"
}

###########################################################
# Download the JSON file from GitHub and save it locally #
###########################################################
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
Invoke-WebRequest -Uri $PartnerLighthousegithubRawUrl -OutFile $LigthousePartnerTemplateOutputFile

##################################
# Connect to Azure and Azure AD #
##################################
Install-Module az -Force
Import-Module az -Force
Install-Module azuread -Force
Import-Module azuread -Force
Connect-AzAccount
$PartnerSubscription = Get-AzSubscription -SubscriptionName $PartnerAzureSubscriptionName
$PartnerSubscriptionId = $PartnerSubscription.Id
Select-AzSubscription -SubscriptionId $PartnerSubscriptionId
$PartnerTenantId = $PartnerSubscription.TenantId
Connect-AzureAD -TenantId $PartnerTenantId

######################################
# Creation of the Azure Entra Group #
######################################
New-AzADGroup -DisplayName $LighthouseAzureADGroupName -Description $LighthouseAzureADGroupDescription -MailNickname $LighthouseAzureADGroupNickName

######################
# Register Provider #
######################
Register-AzResourceProvider -ProviderNamespace Microsoft.ManagedServices

##############################
# Get the ID of Entra Group #
##############################
$LighthouseAzureADGroupNameID = (Get-AzADGroup -DisplayName $LighthouseAzureADGroupName).id

####################################
# Get the Owner ID of Entra Group #
####################################
$LighthouseAzureADGroupOwnerID = (Get-AzADUser -DisplayName $LighthouseAzureADGroupOwner).id

####################################
# Add an Owner to the Entra Group #
####################################
Add-AzureADGroupOwner -ObjectId $LighthouseAzureADGroupNameID -RefObjectId $LighthouseAzureADGroupOwnerID

###########################################
# Add multiple Member to the Entra Group #
###########################################
foreach ($userPrincipalName in $LighthouseAzureADGroupMember) {
    Add-AzADGroupMember -MemberObjectId (Get-AzADUser -UserPrincipalName $userPrincipalName).Id -TargetGroupObjectId $LighthouseAzureADGroupNameID
}

#############################################
# Modify the Json Script with the Variable #
#############################################
$jsonContent = Get-Content -Path $LigthousePartnerTemplateOutputFile | ConvertFrom-Json

## Modify parameters ##
$jsonContent.parameters.mspOfferName.defaultValue = $LighthouseOfferName
$jsonContent.parameters.mspOfferDescription.defaultValue = $LighthouseOfferDescription
## Modify parameters ##

## Modify variables ##
$jsonContent.variables.managedByTenantId = $PartnerTenantId
## Modify variables ##

## Modify authorizations ##
foreach ($authorization in $jsonContent.variables.authorizations) {
    $authorization.principalId = $LighthouseAzureADGroupNameID
    $authorization.principalIdDisplayName = $LighthouseAzureADGroupName
}
## Modify authorizations ##

$jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $LigthousePartnerTemplateOutputFile

## Congratulation you have download and configure the Json Script that you will use in the EndCustomer Tenant ##
## The Json script set the following right ##
## Contributor ##
## User Access Administrator ##
## Security Admin ##
## Log Analytics Contributor ##