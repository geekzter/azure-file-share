#!/usr/bin/env pwsh
#Requires -Version 7

if (!$IsMacOS) {
    Write-Error "This only runs on MacOS, exiting"
    exit
}

# Get configuration
$terraformDirectory = (Join-Path (Get-Item (Split-Path -parent -Path $MyInvocation.MyCommand.Path)).Parent.FullName "terraform")
Push-Location $terraformDirectory
$certPassword = $(terraform output cert_password)
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


# Configure VPN



# Connect VPN



# Mount File share