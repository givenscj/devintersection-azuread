function AddPermissionsToApplication($app, $perms, $creds)
{    
    $url = "https://graph.windows.net/$adTenant/applications/$($app.ObjectID)?api-version=1.6";    
    $method = "PATCH";
    
    ExecuteGraphCall $url $method $creds;    
}

function OpenAllAppPages()
{
    $url = "https://www.facebook.com/settings?tab=applications";
    Start-Process $url;

    $url = "https://twitter.com/settings/applications";
    Start-Process $url;

    $url = "https://security.google.com/settings/security/permissions?pli=1";
    Start-Process $url;

    $url = "https://account.live.com/consent/Manage";
    Start-Process $url;
    
    $url = "http://cgi6.ebay.com/ws/eBayISAPI.dll?ManageESubscriptions";
    Start-Process $url;

    $url = "https://tejadanet-admin.sharepoint.com/_layouts/15/TA_AllAppPrincipals.aspx";
    Start-Process $url;

    $url = "https://www.yammer.com/solliance.net/account/applications";
    Start-Process $url;

    $url = "https://account.activedirectory.windowsazure.com/r#/applications";
    Start-Process $url;

    $url = "https://myapps.microsoft.com";
    Start-Process $url;
}

$global:scriptcommonpath = "C:\github\devintersection-azuread";

#add helper files...
. "$global:scriptcommonpath\common.ps1"

Login "chris@solliance.net";

$name = "DevIntersection_App";
$helpurl = "https://help.solliance.net";
$redirectUrl = "http://localhost:12345";
$secret = "AzureRocks!";

$app = CreateAzureADApplication $name $helpurl $redirectUrl $secret;

$perms = "{`"requiredResourceAccess`":[{`"resourceAppId`":`"00000002-0000-0000-c000-000000000000`",`"resourceAccess`":[{`"id`":`"311a71cc-e848-46a1-bdf8-97ff7156d8e6`",`"type`":`"Scope`"}]}]}";
AddPermissionsToApplication $app $perms $creds;

GenerateConsent $app.ApplicationId $secret $redirectUrl;

$creds = get-credential "chris@solliance.net";