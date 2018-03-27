#AD Graph
#https://msdn.microsoft.com/en-us/library/azure/ad/graph/api/api-catalog

#MS Graph
#https://developer.microsoft.com/en-us/graph

function GetUser($email)
{    
    $url = "https://graph.windows.net/$global:adTenant/users/$email" + "?api-version=1.6";
    $method = "GET";
    $json = ExecuteGraphCall $url $method "User" $global:creds;
    $json;
}

function GetUsers()
{
    return GetGraphObjects "users";
}

function GetApplications()
{
    return GetGraphObjects "applications";    
}

function GetGroups()
{
    return GetGraphObjects "groups";    
}

function GetDomains()
{
    return GetGraphObjects "domains";    
}

function GetPolicies()
{
    return GetGraphObjects "policies";
    
    <#
    $url = "https://graph.windows.net/$global:adTenant/policies?api-version=1.6";
    $method = "GET";
    $json = ExecuteGraphCall $url $method "User" $global:creds;
    $json;
    #>
}

$global:scriptcommonpath = "C:\github\devintersection-azuread";

#add helper files...
. "$global:scriptcommonpath\common.ps1"

Login "chris@solliance.net";

$global:mode = "ADGraph";

<#
GetUser "chris@solliance.net";

$policies = GetPolicies;

$users = GetUsers;

$apps = GetApplications;

$groups = GetGroups;

$domains = GetDomains;

#>

$global:mode = "MSGraph";

#MS Graph "me" endpoint
$me = GetGraphObjects "me";
$me;

#MS Graph "drive" aka OneDrive endpoint
$drive = GetGraphObjects "me/drive";
$drive;

#MS Graph "messages" aka EXO endpoint
$msgs = GetGraphObjects "me/messages";
$msgs;