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
                Name = ($e.Instances.Tags | ? {$_.Key -match "Name"}).Value
                id = $e.instances.InstanceId
                PrivateIP = $e.Instances.PrivateIpAddress
                PublicIP = $e.Instances.PublicIpAddress
                Type = $e.Instances.InstanceType
                SecurityGroupName = $e.Instances.SecurityGroups.GroupName
                SecurityGroupID = $e.Instances.SecurityGroups.GroupId
                Tags = $e.Instances.Tags  # Make an Array of Hash Tags or just leave?
                State = $e.Instances.State.Name
                SubnetID = $e.Instances.SubnetId
                VpcID = $e.Instances.VpcId
            }

            if ($IncludeObject)
            {
                $lo | Add-Member  -Name Object -Value $e -MemberType NoteProperty
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