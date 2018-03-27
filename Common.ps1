function GenerateConsent($clientId, $clientSecret, $redirectUrl)
{
    $url = "https://login.microsoftonline.com/common/oauth2/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUrl";
    Start-Process $url;
}

function CreateAzureAdApplication($appName, $helpUrl, $url, $secret)
{    
    $app = Get-AzureRmADApplication -DisplayNameStartWith $appname;

    if (!$app)
    {
        $secure = ConvertTo-SecureString $secret -AsPlainText -Force;

        $app = New-AzureRmADApplication -DisplayName $appName -HomePage $HelpUrl -IdentifierUris $Url -Password $secure -AvailableToOtherTenants $true;    

        <#
        # Create a Service Principal for the app
        $svcprincipal = New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId

        # Assign the Contributor RBAC role to the service principal
        # If you get a PrincipalNotFound error: wait 15 seconds, then rerun the following until successful
        $roleassignment = New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $azureAdApplication.ApplicationId.Guid
        #>
    }

    return $app;
}

[System.Reflection.Assembly]::LoadWithPartialName("System.Web");

function LoginMicrosoftOnlineUP($username, $password, $clientId)
{
    $url = "https://portal.office.com/login?IdentityProvider=aad";
    $html = DoGet $url;
    $html = DoGet $global:location;

    $buid = $global:urlCookies["login.microsoftonline.com"]["buid"];;
    $esctx = $global:urlCookies["login.microsoftonline.com"]["esctx"];

    
    $sessionid = ParseValue $html "sessionId`":`"" "`"";
    $stsRequest = ParseValue $html "ctx%3d" "\u0026";
    $flowToken = ParseValue $html "sFT`":`"" "`"";
    $canary = ParseValue $html "canary`":`"" "`"";
    
    $url = "https://login.microsoftonline.com/common/login";
    #$post = "login=" + $username + "&passwd=" + [System.Web.HttpUtility]::UrlEncode($password) + "&ctx=" + [System.Web.HttpUtility]::UrlEncode($stsRequest) + "&flowToken=" + [System.Web.HttpUtility]::UrlEncode($flowToken) + "&canary=" + [System.Web.HttpUtility]::UrlEncode($canary) + "&n1=109116&n2=-1464126305000&n3=-1464126305000&n4=109120&n5=109120&n6=109120&n7=109120&n8=NaN&n9=109120&n10=109810&n11=109812&n12=109828&n13=109812&n14=109941&n15=114&n16=110060&n17=110060&n18=110070&n19=892.7529999999997&n20=1&n21=1&n22=1464126417636.5886&n23=1&n24=621.2583&n25=2&n26=0&n27=0&n28=0&n29=-1464126414926&n30=-1464126414926&n31=0&n32=0&n33=0&n34=0&n35=0&n36=0&n37=0&n38=0&n39=0&n40=1390.2025&n41=1515.2474&n42=878.2736&n43=953.8632&type=11&LoginOptions=2&NewUser=1&idsbho=1&PwdPad=&sso=&vv=&uiver=1&i12=1&i13=Firefox&i14=11.0&i15=1920&i16=963&i20=";
    #$post = "i13=0&login=$username&loginfmt=$username&type=11&LoginOptions=3&lrt=&lrtPartition=&hisRegion=&hisScaleUnit=&passwd=$password&ps=2&psRNGCDefaultType=&psRNGCEntropy=&psRNGCSLK=&canary=E7SEmmLvAb9QCqaOe%2BSxE%2BQMrulegUc4N5zuo89dvlE%3D8%3A1&ctx=rQIIAXWRO2_TUACF47zUFgQVC4wdmKjiXD9jRypSWjtNILZpHCeNixQ5zrXjOPZ1nJuX_wSdOyDBgtSNTggh2CshdUZi6IY6ISYGJEh_AMuZjo6Ovu9JhiKp8mOWYTmr1BcLosUzBVakQMFiab7AcAzP0IAacICJH2xt3yGfnlx_Vfbfv-FzNy-l7-fEwyHG0bRcLC4WCxI5jmdD0kZB8QNBXBHED4I4S-dgWDD08_SUZ3iuBARRoADgRYGmOFLtGAu11RypIxubkkF3VwAoSTVotFzGDAzcDZ4NFclYdTttX2n5jCn5lCp1WXVUwWanTmk6AGarPWp0ZFaVfKy1_KVCK5x6KK933eRb-r5WmeEhfRso9hL4K73poDjoRWiKzzLvCC2CYX1wgMIQ2pi8rcEQe7aFPRS-iFEEY-zB6d60asm1NZoEowKct7Ua5Uyed11X8MdiQ68EsLeiVVty2Kalu1Ziuqhb74vHFjThiDt0nSGA4_2B4TsyVuumaU-rgh5Fy1rAJklp3k-OY6q_0H3Ua_ZwXXC1qhZ0tKrVHGu1kaBPSheZ_BprgMLLzL31qdAb7EQxcrwxvMoSN9m7IFPe2NjaTj1K7aR-Z4m3ubUtA7zWP_95pX65_nTxd8amLnNFuaTLQdCYV_ri0cHE0uCuvpR3j5R4NoauYbMql8yQIA7mY3lPKFOneeI0n_-ZT33c_J_ofw2&hpgrequestid=539e3055-fcbe-4e8f-bfe1-bcb2ff753400&flowToken=AQABAAEAAABHh4kmS_aKT5XrjzxRAtHzAVrXggl8gblPkLJDOV_k156Ufc8NSHCgAx7bC15dsHbMqCN4FHBubxDiWf7pNSiijgajOOhl25ALa0auI5oFqdHcTX8rJwd_IcZtFmNLePzWNEhPpfF29muHSJrPEJLJbfcgS7xMl33YSYMzdsyAuYl1M5zPHzxLuGqWnnOpXThqCLsKzkcQJUFhenpAdXWSCGB_VE8Jg_OMe4h8NMNG_hfOj_dkdJkVu22-2yhz1xGi0b_NoKse1_q9I6ZfL4XzTPDm3ZvmcOShpBXC41WTFBOvL4AJAEbhcnLfVeir1y9pLLBvNU_c1ZSd5Tz_nw4RojPojK-WHRYdY074hYVMEskyB58da9w0EsjFnPuqTEJ6_0N-MauqAptpRXJqgizOP5ixFnHsGGMILkQQcpzOfyMA-LZly9a1BC9Fk-lXJEoH7pG7z-SHJkHbg1jRrzikTMiIELXuuRbKk3V5HDy57yAA&PPSX=&NewUser=1&FoundMSAs=&fspost=0&i21=0&CookieDisclosure=0&IsFidoSupported=0&i2=102&i17=&i18=&i19=53576"    
    #string post = "login=" + HttpUtility.UrlEncode(username) + "&passwd=" + HttpUtility.UrlEncode(password) + "&ctx=" + HttpUtility.UrlEncode(stsRequest) + "&flowToken=" + HttpUtility.UrlEncode(flowToken) + "&n1=90530&n2=-1435115391000&n3=-1435115391000&n4=90530&n5=90530&n6=90530&n7=90549&n8=90710&n9=90765&n10=90765&n11=91122&n12=91124&n13=91139&n14=91628&n15=131&n16=91942&n17=91968&n18=91986&n19=0&n20=1&n21=0&n22=0&n23=1&n24=214.9999999674037&n25=0&n26=8&n27=0&n28=0&n29=-1435115482594&n30=-1435115482594&n31=0&n32=0&n33=0&n34=0&n35=0&n36=0&n37=0&n38=0&n39=0&n40=1280.0000000279397&n41=1415.000000037253&n42=1180.9999999823049&n43=1456.000000005588&type=11&LoginOptions=2&NewUser=1&idsbho=1&PwdPad=&sso=&vv=&uiver=1&i12=1&i13=Chrome&i14=43.0.2357.130&i15=929&i16=909&i20=";    
    
    $post = "i13=0&login=" + $username + "&loginfmt=" + $username + "&type=11&LoginOptions=3&lrt=&lrtPartition=&hisRegion=&hisScaleUnit=&passwd=" + [System.Web.HttpUtility]::UrlEncode($password) + "&ps=2&psRNGCDefaultType=&psRNGCEntropy=&psRNGCSLK=&canary=" + [System.Web.HttpUtility]::UrlEncode($canary) + "&ctx=" + [System.Web.HttpUtility]::UrlEncode($stsRequest) + "&hpgrequestid=$sessionId&flowToken=" + [System.Web.HttpUtility]::UrlEncode($flowToken) + "&PPSX=&NewUser=1&FoundMSAs=&fspost=0&i21=0&CookieDisclosure=0&IsFidoSupported=0&i2=1&i17=&i18=&i19=19667"        
    $html = DoPost $url $post;

}

function LoginMicrosoftOnline($creds)
{
    $c = new-object System.Net.NetworkCredential($creds.username, $creds.Password);
    $password = $c.Password;
    $username = $c.UserName;

    LoginMicrosoftOnlineUP $username $password;
}

function ParseValue($line, $startToken, $endToken)
{
    if ($startToken -eq $null)
    {
        return "";
    }

    if ($startToken -eq "")
    {
        return $line.substring(0, $line.indexof($endtoken));
    }
    else
    {
        try
        {
            $rtn = $line.substring($line.indexof($starttoken));
            return $rtn.substring($startToken.length, $rtn.indexof($endToken, $startToken.length) - $startToken.length).replace("`n","").replace("`t","");
        }
        catch [System.Exception]
        {
            $message = "Could not find $starttoken"
            #write-host $message -ForegroundColor Yellow
        }
    }

}


function Login($email, $refresh)
{
    if (!$global:creds -or $refresh)
    {
        $global:creds = get-credential $email;
    }

    if (!$global:azcontext)
    {
        $global:azcontext = Login-AzureRmAccount -Credential $global:creds;
        $global:adTenant = $azcontext.Context.Tenant.Directory;
        $global:authority = "https://login.microsoftonline.com/$adTenant";
    }

    Connect-AzureAD -Credential $global:creds;    
}

function CreateAssertion($flow, $resource, $token, $value, $clientId, $clientSecret)
{
    $clientCred = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential($clientId, $clientSecret);
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority;

    if ($flow -eq "User")
    {
        $assert = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.UserAssertion($token,"urn:ietf:params:oauth:grant-type:jwt-bearer",$value);
        $result = $authContext.AcquireTokenAsync($resource, $clientCred, $assert);
    }

    if ($flow -eq "Certificate")
    {
        $assert = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.UserAssertion($token,"urn:ietf:params:oauth:grant-type:jwt-bearer",$value);
        $result = $authContext.AcquireTokenAsync($resource, $clientCred, $assert);                
    }    

    return $result.Result.AccessToken;
}

function GetGraphAuthHeader() {
    
    # Load ADAL Assemblies
    $asm = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.IdentityModel.Clients.ActiveDirectory");

    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"  # Set well-known client ID for AzurePowerShell
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob" # Set redirect URI for Azure PowerShell
    $resourceAppIdURI = "https://graph.windows.net/" # resource we want to use
    
    # Create Authentication Context tied to Azure AD Tenant
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    
    # Acquire token
    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")
    $authHeader = $authResult.CreateAuthorizationHeader()
    $headers = @{"Authorization" = $authHeader; "Content-Type"="application/json"}
    return $headers
}

function GetUserToken($creds, $resource)
{    
    $c = new-object System.Net.NetworkCredential($creds.username, $creds.Password);
    $password = $c.Password;
    $username = $c.UserName;
    $PayLoad="resource=$resource&client_id=1950a258-227b-4e31-a9cf-717495945fc2&grant_type=password&username="+$username+"&scope=openid&password="+$Password; 
    $Response=Invoke-WebRequest -Uri "https://login.microsoftonline.com/Common/oauth2/token" -Method POST -Body $PayLoad;
    $ResponseJSON=$Response|ConvertFrom-Json;
    $ResponseJSON;
}

function ExecuteGraphCall($url, $method, $mode, $authType, $creds)
{
    if ($mode -eq "MSGraph")
    {
        $resourceUrl = "https://graph.microsoft.com/";
    }

    if ($mode -eq "ADGraph")
    {
        $resourceUrl = "https://graph.windows.net/";
    }

    if($authType -eq "App")
    {
        $headers = GetGraphAuthHeader;
    }

    if ($authType -eq "User")
    {
        $token = GetUserToken $creds $resourceUrl;
        $at =  [System.Web.HttpUtility]::UrlEncode($token.access_token);
        $authHeader = "Bearer " + $at;
        $headers = @{"Authorization" = $authHeader; "Content-Type"="application/json"}
    }    
    
    write-host $url;
    $result = Invoke-RestMethod -Uri $url -Method $method -Headers $headers -Body $perms;
    return $result;
}

$global:adgraphUrl = "https://graph.windows.net";
$global:adgraphVersion = "1.6";

$global:msgraphUrl = "https://graph.microsoft.com";
$global:msgraphVersion = "v1.0";

$global:mode = "ADGraph";
#$global:mode = "MSGraph";

function GetGraphObjects($type)
{
    if ($global:mode -eq "ADGraph")
    {
        $url = "$global:adgraphUrl/$global:adTenant/$type" + "?api-version=$global:adgraphversion";
        $method = "GET";
        $json = ExecuteGraphCall $url $method $global:Mode "User" $global:creds;
        return $json;
    }

    if ($global:mode -eq "MSGraph")
    {
        $url = "$global:msgraphUrl/$global:msgraphVersion/$type";
        $method = "GET";
        $json = ExecuteGraphCall $url $method $global:Mode "User" $global:creds;
        return $json;
    }
}

function GetGraphObject($type, $id)
{
    $url = "$graphUrl/$global:adTenant/$type/$id" + "?api-version=1.6";
    $method = "GET";
    $json = ExecuteGraphCall $url $method "User" $global:creds;
    return $json;
}
