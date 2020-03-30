<#
.SYNOPSIS
Returns configuration information of EC2 Instances.
.DESCRIPTION
Returns a PSCUSTOMOBJECT of configuration information of EC2 Instances.  Optionally
adds the source EC2-Instance-Object if the IncludeObject Parameter is specified.
.NOTES

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
Start all instances with a Name starting with "WEB" :
($a1 | Where-Object -Property Name -match "^WEB").Object | Start-EC2Instance
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

<#

Find its way into help or make a smoother way of accessing it?
$aa = Get-EC2Instance |  Show-EC2Instance -IncludeObject
($aa|? name -match 03).Object  |  Start-EC2Instance
or

$r1 = Get-EC2Instance | Show-EC2Instance -IncludeObject
$r1 | ? state -Match run |select -expand object | Stop-EC2Instance



foreach ($e in $ee[0].instances.Tags) {if ($e.Key -match "Name") {$e.Value}   }


$h = @{}
foreach ($e in $ee[0].instances.Tags) { $h.add($e.Key , $e.Value)   }
$h.ContainsKey("Name")

$k = $h.ContainsKey("Name") ?  $h.'Name' :  "NameLess"
$k
Nginx01
$k = $h.ContainsKey("Nameeeee") ?  $h.'Name' :  "NameLess"
$k
NameLess
#>