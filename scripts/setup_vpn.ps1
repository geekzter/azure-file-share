#!/usr/bin/env pwsh
#requires -Version 7
function AzLogin (
    [parameter(Mandatory=$false)][switch]$DisplayMessages=$false
) {
    # Azure CLI
    Invoke-Command -ScriptBlock {
        $private:ErrorActionPreference = "Continue"
        # Test whether we are logged in
        $script:loginError = $(az account show -o none 2>&1)
        if (!$loginError) {
            $script:userType = $(az account show --query "user.type" -o tsv)
            if ($userType -ieq "user") {
                # Test whether credentials have expired
                $Script:userError = $(az ad signed-in-user show -o none 2>&1)
            } 
        }
    }
    if ($loginError -or $userError) {
        az login -o none
    }
}
if (!$IsMacOS) {
    Write-Error "This only runs on MacOS, exiting"
    exit
}

# Get configuration
$terraformDirectory = (Join-Path (Get-Item (Split-Path -parent -Path $MyInvocation.MyCommand.Path)).Parent.FullName "terraform")
Push-Location $terraformDirectory
$certPassword = $(terraform output cert_password  2>$null)
$gatewayId    = $(terraform output gateway_id     2>$null)
Pop-Location

$certificateDirectory = (Join-Path (Get-Item (Split-Path -parent -Path $MyInvocation.MyCommand.Path)).Parent.FullName "certificates")
$null = New-Item -ItemType Directory -Force -Path $certificateDirectory 

$rootCertificateCommonName = "P2SRootCert"
$clientCertificateCommonName = "P2SChildCert"

# Install certificates
#security unlock-keychain ~/Library/Keychains/login.keychain
if (Test-Path $certificateDirectory/root_cert_public.pem) {
    if (security find-certificate -c $rootCertificateCommonName 2>$null) {
        Write-Warning "Certificate with common name $rootCertificateCommonName already exixts"
        # Prompt to overwrite
        Write-Host "Continue importing $certificateDirectory/root_cert_public.pem? Please reply 'yes' - null or N skips import" -ForegroundColor Cyan
        $proceedanswer = Read-Host 
        $skipRootCertImport = ($proceedanswer -ne "yes")
    } 

    if (!$skipRootCertImport) {
        Write-Host "Importing root certificate $certificateDirectory/root_cert_public.pem..."
        security add-trusted-cert -r trustRoot -k ~/Library/Keychains/login.keychain $certificateDirectory/root_cert_public.pem
    }
} else {
    Write-Host "Certificate $certificateDirectory/root_cert_public.pem does not exist, have you run 'terraform apply' yet?"
    exit
}
if (Test-Path $certificateDirectory/client_cert.p12) {
    if (security find-certificate -c $clientCertificateCommonName 2>$null) {
        Write-Warning "Certificate with common name $clientCertificateCommonName already exixts"
        # Prompt to overwrite
        Write-Host "Continue importing $certificateDirectory/client_cert.p12? Please reply 'yes' - null or N skips import" -ForegroundColor Cyan
        $proceedanswer = Read-Host 
        $skipClientCertImport = ($proceedanswer -ne "yes")
    } 

    if (!$skipClientCertImport) {
        Write-Host "Importing client certificate $certificateDirectory/client_cert.p12..."
        security import $certificateDirectory/client_cert.p12 -P $certPassword
    }
} else {
    Write-Host "Certificate $certificateDirectory/client_cert.p12 does not exist, have you run 'terraform apply' yet?"
    exit
}

# Download VPN package
AzLogin
if ($gatewayId) {
    $vpnPackageUrl = $(az network vnet-gateway vpn-client generate --ids $gatewayId --authentication-method EAPTLS -o tsv)

    # Download VPN Profile
    Write-Host "Downloading VPN profile..."
    $packageFile = New-TemporaryFile
    Invoke-WebRequest -UseBasicParsing -Uri $vpnPackageUrl -OutFile $packageFile
    $tempPackagePath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    $null = New-Item -ItemType "directory" -Path $tempPackagePath
    # Extract package archive
    Expand-Archive -Path $packageFile -DestinationPath $tempPackagePath
    $vpnProfileFile = Join-Path $tempPackagePath Generic VpnSettings.xml
    Write-Verbose "VPN Profile is ${vpnProfileFile}"

    # Locate VPN Server setting
    $vpnProfileXml = [xml](Get-Content $vpnProfileFile)
    $serverNode = $vpnProfileXml.SelectSingleNode("//*[name()='VpnServer']")
    $vpnServer = $serverNode.InnerText
    Write-Host "VPN Server is $vpnServer"
    Write-Verbose "VPN Server is $vpnServer"


} else {
    Write-Warning "Gateway not found, have you run 'terraform apply' yet?"    
}

# Configure VPN



# Connect VPN



# Mount File share