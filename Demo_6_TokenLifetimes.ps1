function SetDefaultTokenLifetime()
{
    $newDefaultTokenLifetimePolicy = @('{
        "TokenLifetimePolicy":
        {
            "Version":1,
            "AccessTokenLifetime":"01:00:00",
            "MaxInactiveTime":"90.00:00:00",
            "MaxAgeSingleFactor":"until-revoked",
            "MaxAgeMultiFactor":"until-revoked",
            "MaxAgeSessionSingleFactor":"until-revoked",
            "MaxAgeSessionMultiFactor":"until-revoked"
        }
    }') 

    New-AzureADPolicy -Definition $newDefaultTokenLifetimePolicy -DisplayName "OrganizationDefaultPolicyScenario" -IsOrganizationDefault $true -Type "TokenLifetimePolicy";
}

function SetTokenLifetime($lifetime)
{
    $newDefaultTokenLifetimePolicy = @('{
        "TokenLifetimePolicy":
        {
            "Version":1,
            "AccessTokenLifetime":"00:10:00",
            "MaxInactiveTime":"00:10:00",
            "MaxAgeSingleFactor":"00:10:00",
            "MaxAgeMultiFactor":"00:10:00",
            "MaxAgeSessionSingleFactor":"00:10:00",
            "MaxAgeSessionMultiFactor":"00:10:00"
        }
    }') 

    New-AzureADPolicy -Definition $newDefaultTokenLifetimePolicy -DisplayName "OrganizationDefaultPolicyScenario" `-IsOrganizationDefault $true -Type "TokenLifetimePolicy";
}

function TestIdToken()
{
}

function TestAccessToken()
{
}

function TestRefreshToken()
{
}

$global:scriptcommonpath = "C:\github\devintersection-azuread";

#add helper files...
. "$global:scriptcommonpath\common.ps1"

Login "chris@solliance.net";

#this is a new command set...
Import-Module AzureADPreview -Force;

#old tenants won't get anything back = defaults...
$policies = Get-AzureAdPolicy;

SetDefaultTokenLifetime;

$orgDefaultPolicy = Get-AzureADPolicy | Where-Object {$_.Type -eq "TokenLifetimePolicy" -and $_.IsOrganizationDefault -eq $true}

SetTokenLifetime "00:10:00";

#Revoke-AzureADUserAllRefreshToken;