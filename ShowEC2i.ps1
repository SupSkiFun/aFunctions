<#
.SYNOPSIS
Returns configuration information from EC2 Instances.
.DESCRIPTION
Returns a PSCUSTOMOBJECT of configuration information from EC2 Instances.  Optionally
adds the source EC2-Instance-Object if the IncludeObject Parameter is specified.
.NOTES
Within the Object:
1) The Name Parameter will be empty if a name has not been specified.
2) Tags can be seen by returning the object into a variable (e.g. $myVar), then $myVar.Tags
3) The .Object property is available if -IncludeObject was specified.  This property can be accessed
by using .object or via Select-Object -ExpandProperty Object.  Both are shown in Example 4.

For optimal JSON Output, return the object into a variable without specifying -IncludeObject.
$myVar = Get-EC2Instance -InstanceId i-0e90783335830aaaa | Show-EC2Instance
$jVar = $myVar | ConvertTo-Json
.PARAMETER EC2Instance
Mandatory. Output from AWS Get-EC2Instance (Module AWS.Tools.EC2). See Examples.
[Amazon.EC2.Model.Reservation]
.PARAMETER IncludeObject
Optional. If specified places the source EC2-Instance-Object within the Object
NoteProperty of the PSCUSTOMOBJECT.  Useful for piping.  See Notes and Examples.
.INPUTS
AWS Instance from Get-EC2Instance:
[Amazon.EC2.Model.Reservation]
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.AWS.EC2Instance.Info
.EXAMPLE
Return a custom object from one EC2 Instance:
Get-EC2Instance -InstanceId i-0e90783335830aaaa | Show-EC2Instance
.EXAMPLE
Return a custom object from two EC2 Instances into a variable:
$myVar = Get-EC2Instance -InstanceId i-0e90783335830aaaa , i-0e20784445830bbbb | Show-EC2Instance
.EXAMPLE
Return a custom object from one EC2 Instance, including the source Object, into a variable:
$myVar = Get-EC2Instance -InstanceId i-0e90783335830aaaa | Show-EC2Instance -IncludeObject
.EXAMPLE
Return a custom object from all EC2 Instances in a region, including the source Object, into a variable:
$myVar = Get-EC2Instance -Region us-east-1 | Show-EC2Instance -IncludeObject
...then...
Start all instances in $myVar with a Name beginning with "WEB" :
($myVar | Where-Object -Property Name -Match "^WEB").Object | Start-EC2Instance
...alternative syntax to start all instances in $myVar with a Name beginning with "WEB" :...
$myvar | Where-Object -Property Name -Match "^WEB" | Select-Object -ExpandProperty Object | Start-EC2Instance
#>
Function Show-EC2Instance
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Amazon.EC2.Model.Reservation[]] $EC2Instance,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Switch] $IncludeObject
    )

    Process
    {
        foreach ($e in $EC2Instance)
        {
            $lo = [pscustomobject]@{
                Name = ($e.Instances.Tags |
                    Where-Object {$_.Key -match "Name"}).Value
                ID = $e.instances.InstanceId
                PrivateIP = $e.Instances.PrivateIpAddress
                PublicIP = $e.Instances.PublicIpAddress
                Type = $e.Instances.InstanceType
                SecurityGroupName = $e.Instances.SecurityGroups.GroupName
                SecurityGroupID = $e.Instances.SecurityGroups.GroupId
                Tags = $e.Instances.Tags
                State = $e.Instances.State.Name
                SubnetID = $e.Instances.SubnetId
                VpcID = $e.Instances.VpcId
            }

            if ($IncludeObject)
            {
                $lo |
                    Add-Member  -Name Object -Value $e -MemberType NoteProperty
            }
            $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.AWS.EC2Instance.Info')
            $lo
        }
    }
}