#https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-v2-protocols

function GetConfig($html)
{
    try
    {
        $json = ConvertFrom-Json $html;

        if ($json.error_description)
        {
            write-host $json.error_description;
        }
    }
    catch
    {
    }

    $config = ParseValue $html "Config=" "]]";

    if ($config)
    {
        $config = $config.Substring(0, $config.Length-3);
        $json = ConvertFrom-Json $config;    

        #check for error...
        if ($json.error)
        {
            write-host $($json.error_description);
            return $null;
        }
    }

    if ($global:location.contains("error="))
    {
        $errorMessage = ParseValue $global:location "description=" "&";
        write-host $errorMessage;
    }

    return $json;
}

function AuthorizeApp($html, $isAdmin)
{
    if ($isAdmin)
    {
        #Do an admin consent...
        $url = "https://login.microsoftonline.com/$global:adTenant/adminconsent?client_id=$clientId&state=12345&redirect_uri=$replyUrl";
        $html = DoGet $url;

        $config = GetConfig $html;
    }
    else
    {
        $sessionid = ParseValue $html "sessionId`":`"" "`"";
        $stsRequest = ParseValue $html "ctx%3d" "\u0026";
        $flowToken = ParseValue $html "sFT`":`"" "`"";
        $canary = ParseValue $html "apiCanary`":`"" "`"";
        $ctx = ParseValue $html "sCtx`":`"" "`"";

        #accept the consent
        $url = "https://login.microsoftonline.com/$global:adTenant/Consent/Set";
        $post = "acceptConsent=true&ctx=$ctx&hpgrequestid=$sessionId&flowToken=$flowToken&canary=$canary&i2=&i17=&i18=&i19=49619";
        $html = DoPost $url $post;  

        $config = GetConfig $html;
    }
}

function OAuth_AuthorizationCodeGrant($clientId, $clientSecret, $replyUrl)
{
    #login to microsoftonline...
    LoginMicrosoftOnline $global:creds;

    #start the consent process...or get the token...depends!
    $url = "https://login.microsoftonline.com/$global:adTenant/oauth2/v2.0/authorize?client_id=$clientId&response_type=code&redirect_uri=$replyUrl&response_mode=query&scope=openid%20offline_access%20https%3A%2F%2Fgraph.microsoft.com%2Fmail.read&state=12345";    
    $html = DoGet $url;

    $config = GetConfig $html;

    if ($config.urlPost -and $config.urlPost.contains("/Consent/Set"))
    {
        #do an authorization...
        AuthorizeApp $html;

        $url = "https://login.microsoftonline.com/$global:adTenant/oauth2/v2.0/authorize?client_id=$clientId&response_type=code&redirect_uri=$replyUrl&response_mode=query&scope=openid%20offline_access%20https%3A%2F%2Fgraph.microsoft.com%2Fmail.read&state=12345";    
        $html = DoGet $url;
    }    

    #get a code...
    $code = ParseValue $global:location "code=" "&";

    #get a token...
    $post = "client_id=$clientId&scope=https%3A%2F%2Fgraph.microsoft.com%2Fmail.read&code=$code&redirect_uri=$replyUrl&grant_type=authorization_code&client_secret=$clientSecret";
    $url = "https://login.microsoftonline.com/$global:adTenant/oauth2/v2.0/token"
    $html = DoPost $url $post;

    $json = ConvertFrom-Json $html;
    $json;
}

function OAuth_ClientCredentialsGrant($clientId, $clientSecret, $replyUrl)
{
    #login to microsoftonline...
    LoginMicrosoftOnline $global:creds;            

    #try to get token...might need to consent...
    $url = "https://login.microsoftonline.com/$global:adTenant/oauth2/v2.0/token";
    $post = "client_id=$clientId&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default&client_secret=$clientSecret&grant_type=client_credentials";        
    $html = DoPost $url $post;

    $config = GetConfig $html;

    if (!$config)
    {
        $json = ConvertFrom-Json $html;
        $json;
    }
}

function OAuth_ImplicitGrant($clientId, $clientSecret, $replyUrl)
{
    #https://msdn.microsoft.com/en-us/skype/websdk/docs/troubleshooting/auth/aadauth-enableimplicitoauth?f=255&MSPPError=-2147217396
    write-host -ForegroundColor yellow "Warning - Implict Flow must be enabled for application";

    #login to microsoftonline...
    LoginMicrosoftOnline $global:creds;

    #get an id token and token - fragment
    $url = "https://login.microsoftonline.com/$global:adTenant/oauth2/v2.0/authorize?client_id=$clientId&response_type=id_token+token&redirect_uri=$replyUrl&scope=openid%20https%3A%2F%2Fgraph.microsoft.com%2Fmail.read&response_mode=fragment&state=12345&nonce=678910"
    $html = DoGet $url;
    
    $config = GetConfig $html;

    #get a token...fragment
    $loginHint = $global:creds.UserName;
    $url = "https://login.microsoftonline.com/$global:adTenant/oauth2/v2.0/authorize?client_id=$clientId&response_type=token&redirect_uri=$replyUrl&scope=https%3A%2F%2Fgraph.microsoft.com%2Fmail.read&response_mode=fragment&state=12345&nonce=678910&prompt=none&domain_hint=organizations&login_hint=$loginHint";
    $html = DoGet $url;

    $config = GetConfig $html;

    if (!$config)
    {
        $code = ParseValue $global:location "access_token=" "&";
        $code;
    }    
}

function OAuth_OnBehalfOfGrant($clientId, $clientSecret, $replyUrl)
{
    #login to microsoftonline...
    LoginMicrosoftOnline $global:creds;

    $resource = "https://graph.microsoft.com";

    #get a user token
    $token = GetUserToken $global:creds $resource;
    $accessToken = $token.access_token;

    #create assertion token...
    $assertion = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.UserAssertion($accessToken,"urn:ietf:params:oauth:grant-type:jwt-bearer",$global:creds.UserName);    
    
    #$assertion = CreateAssertion "User" $resource $token $global:creds.username $clientId $clientSecret;

    #try it out...
    $url = "https://login.microsoftonline.com/$global:adTenant/oauth2/v2.0/token";
    $post = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&client_id=$clientId&client_secret=$clientSecret&assertion=$($assertion.assertion)&scope=https://graph.microsoft.com/user.read&requested_token_use=on_behalf_of";
    $html = DoPost $url $post;

    $config = GetConfig $html;

    if (!$config)
    {
        $json = ConvertFrom-Json $html;
        $json;
    }
}

function OpenId_Connect($clientId, $replyUrl)
{
    #login to microsoftonline...
    LoginMicrosoftOnline $global:creds;

    #get the openId configuration endpoints
    $url = "https://login.microsoftonline.com/$global:adTenant/v2.0/.well-known/openid-configuration";
    $html = DoGet $url;

    $json = ConvertFrom-json $html;
    $json;

    #get the id token
    $url = "https://login.microsoftonline.com/$global:adTenant/oauth2/v2.0/authorize?client_id=$clientId&response_type=id_token&redirect_uri=$replyUrl&response_mode=form_post&scope=openid&state=12345&nonce=678910";
    $html = DoGet $url;

    $config = GetConfig $html;

    if ($config.urlPost -and $config.urlPost.contains("/Consent/Set"))
    {
        #do an authorization...
        AuthorizeApp $html;
    }
    else
    {
        #we must be authorized...
        $idToken = ParseValue $html "name=`"id_token`" value=`"" "`"";
    }

    #get an access token...
    $url = "https://login.microsoftonline.com/$global:adTenant/oauth2/v2.0/authorize?client_id=$clientId&response_type=id_token%20code&redirect_uri=$replyUrl&response_mode=form_post&scope=openid%20offline_access%20https%3A%2F%2Fgraph.microsoft.com%2Fmail.read&state=12345&nonce=678910";
    $html = DoGet $url;

    $config = GetConfig $html;

    if ($config.urlPost -and $config.urlPost.contains("/Consent/Set"))
    {
        #do an authorization...
        AuthorizeApp $html;        
    }
}


$global:scriptcommonpath = "C:\github\devintersection-azuread";

#add helper files...
. "$global:scriptcommonpath\common.ps1"
. "$global:scriptcommonpath\util.ps1"
. "$global:scriptcommonpath\httphelper.ps1"

$user = "chris@solliance.net";
Login $user;

$name = "DevIntersection_App";
$helpurl = "https://help.solliance.net";
$replyUrl = "http://localhost:12345";
$secret = "AzureRocks!";

$url = "https://portal.azure.com/#@solliance.net/blade/Microsoft_AAD_IAM/ApplicationBlade/appId/553084af-ffbf-480d-9004-4c8dddcf8278/objectId/b1ef58f9-b27f-49d7-820e-00cab87a547f";
start-process $url;

$app = CreateAzureADApplication $name $helpurl $replyUrl $secret;

$clientId = $app.ApplicationId;
$clientSecret = $secret;

OAuth_AuthorizationCodeGrant $clientId $clientSecret $replyUrl;

OAuth_ClientCredentialsGrant $clientId $clientSecret $replyUrl;

OAuth_OnBehalfOfGrant $clientId $clientSecret $replyUrl;

OAuth_ImplicitGrant $clientId $clientSecret $replyUrl;

OpenId_Connect $clientId $replyUrl;