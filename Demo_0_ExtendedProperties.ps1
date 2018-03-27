function CreateExtendedProperty($app, $name, $type)
{
    $props = $app | Get-AzureADApplicationExtensionProperty;

    foreach($p in $props)
    {
        if ($p.name.endswith($name))
        {
            $prop = $p;
        }
    }    

    if (!$prop)
    {
        try
        {
            $prop = New-AzureADApplicationExtensionProperty -ObjectId $app.ObjectId -Name $name -DataType $type -TargetObjects "User";
            return $prop.name;
        }
        catch
        {
            $propName = ParseValue $_.Exception.message "name " ".";
            return $propName;
        }
    }

    return $prop.Name;
}

function InitExtProp()
{
    $appName = "My Properties Bag App";
    $app = Get-azureadapplication -SearchString $appName;

    if (!$app)
    {
        $app = (New-AzureADApplication -DisplayName $appName -IdentifierUris "https://localhost");        
    }   

    <#
    YOU HAVE TO HAVE A SVC PRIN for these calls to work!
    #>

    $prin = Get-AzureADServicePrincipal -SearchString $appName; 

    if(!$prin)
    {
        $prin = New-AzureADServicePrincipal -AppId $app.AppId;
    }

    $prop = CreateExtendedProperty $app "SkypeId" "String";

    return $prop;
}

$global:scriptcommonpath = "C:\github\devintersection-azuread";

#add helper files...
. "$global:scriptcommonpath\common.ps1"
. "$global:scriptcommonpath\util.ps1"

$email = "chris@solliance.net";
Login $email;

$users = Get-AzureADUser -Searchstring "chris";

foreach($user in $users)
{
    if($user.UserPrincipalName -eq $email)
    {
        $userId = $user.objectId;
    }
}

Get-AzureADUser -ObjectId $UserId | Select -ExpandProperty ExtensionProperty;

$propName = InitExtProp;
Set-AzureADUserExtension -ObjectId $UserId -ExtensionName $propName -ExtensionValue "givenscj";

Get-AzureADUser -ObjectId $UserId | Select -ExpandProperty ExtensionProperty;