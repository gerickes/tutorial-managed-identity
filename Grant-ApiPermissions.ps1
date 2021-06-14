# Object Id of the managed identity
$ObjIdDev =  "<object id of the managed identity>"

$PermissionMap = @{
    '00000003-0000-0000-c000-000000000000' = @( # Microsoft Graph
        'User.Read.All'
        'Group.Read.All'
        'Group.ReadWrite.All'
        'Sites.Read.All'
        'Sites.ReadWrite.All'
    )
    '00000003-0000-0ff1-ce00-000000000000' = @( # Office 365 SharePoint Online
        'Sites.FullControl.All'
    )
}

Connect-AzureAD

# Get Service Principal using ObjectId
$ManagedIdentity = Get-AzureADServicePrincipal -ObjectId $ObjIdDev

Get-AzureADServicePrincipal -All $true | Where-Object { $_.AppId -in $PermissionMap.Keys} -PipelineVariable SP | ForEach-Object {

    $SP.AppRoles | Where-Object { $_.Value -in $PermissionMap[$SP.AppId] -and $_.AllowedMemberTypes -contains "Application" } -PipelineVariable AppRole | ForEach-Object {
        try {
            New-AzureAdServiceAppRoleAssignment -ObjectId $ManagedIdentity.ObjectId `
                                            -PrincipalId $ManagedIdentity.ObjectId `
                                            -ResourceId $SP.ObjectId `
                                            -Id $_.Id `
                                            -ErrorAction Stop
        } catch [Microsoft.Open.AzureAD16.Client.ApiException] {
            if ($_.Exception.Message -like '*Permission being assigned already exists on the object*') {
                'Permission {0} already set on {1}.' -f $AppRole.Value, $SP.DisplayName | Write-Warning
            } else {
                throw $_.Exception
            }
        }
    }
}