#custom policies - https://docs.microsoft.com/en-us/azure/active-directory-b2c/active-directory-b2c-overview-custom

function OpenPortal()
{
    $url = "https://portal.azure.com/#@solliance.net/blade/Microsoft_AAD_B2CAdmin/TenantManagementMenuBlade/overview";
    Start-Process $url;
}

function GenerateSignIn($tenant, $signInPolicy, $clientId, $replyUrl)
{
    $url = "https://login.microsoftonline.com/$tenant.onmicrosoft.com/oauth2/v2.0/authorize?p=$signInPolicy&client_id=$clientId&nonce=defaultNonce&redirect_uri=$replyUrl&scope=openid&response_type=id_token&prompt=login";
    Start-Process $url;
}

$global:scriptcommonpath = "C:\github\devintersection-azuread";

#add helper files...
. "$global:scriptcommonpath\common.ps1"

Login "chris@solliance.net";

$signInPolicy = "B2C_1_Solliance-Policy-Main";
$tenant = "solliancenetb2c";
$clientId = "a87f72f4-5832-47b4-be3d-b6c5bf695113";
$replyUrl = "https://localhost:44332/";

OpenPortal;

GenerateSignIn $tenant $signInPolicy $clientId $replyUrl;