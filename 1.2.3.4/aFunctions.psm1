using module .\aClass.psm1

<#
.SYNOPSIS
Returns configuration information from EC2 Instances.
.DESCRIPTION
Returns a PSCUSTOMOBJECT of configuration information from EC2 Instances.
.NOTES
1) The object provided from Get-EC2Instance is stored in the NoteProperty Object.
2) The Name NoteProperty will be empty if an EC2 Instance name has not been specified.
3) Tags can be seen by returning the object into a variable (e.g. $myVar), then $myVar.Tags
4) Optimal JSON output is demonstrated in Example 4.
.PARAMETER EC2Instance
Mandatory. Output from AWS Get-EC2Instance (Module: AWS.Tools.EC2). See Examples.
[Amazon.EC2.Model.Reservation]
.INPUTS
AWS Instance from Get-EC2Instance [Amazon.EC2.Model.Reservation]
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.AWS.EC2Instance.Info
.EXAMPLE
Return a custom object from one EC2 Instance:
Get-EC2Instance -InstanceId i-0e90783335830aaaa | Show-EC2Instance
.EXAMPLE
Return a custom object from two EC2 Instances into a variable:
$myVar = Get-EC2Instance -InstanceId i-0e90783335830aaaa , i-0e20784445830bbbb | Show-EC2Instance
.EXAMPLE
Start all EC2 Instances with a name of "test":
(Get-EC2Instance | Show-EC2Instance | Where Name -match test).Object | Start-EC2Instance
.EXAMPLE
Return a custom object from one EC2 Instance, converting the output to JSON:
$myVar = Get-EC2Instance -InstanceId i-0e90783335830aaaa | Show-EC2Instance
$jVar = $myVar | Select-Object * -ExcludeProperty Object | ConvertTo-Json -Depth 4
.LINK
Get-EC2Instance
#>

Function Show-EC2Instance
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Amazon.EC2.Model.Reservation[]] $EC2Instance
    )

    Process
    {
        foreach ($e in $EC2Instance.Instances)
        {
            $lo = [aClass]::MakeEC2IObj($e)
            $lo
        }
    }
}

<#
.SYNOPSIS
Returns configuration information from VPC(s).
.DESCRIPTION
Returns a PSCUSTOMOBJECT of configuration information from VPC(s).
.NOTES
1) The object provided from Get-EC2Vpc is stored in the NoteProperty Object.
2) The Name NoteProperty will be empty if a VPC name has not been specified.
3) Tags can be seen by returning the object into a variable (e.g. $myVar), then $myVar.Tags
4) Optimal JSON output is demonstrated in Example 3.
.PARAMETER EC2Instance
Mandatory. Output from AWS Get-EC2Vpc (Module: AWS.Tools.EC2). See Examples.
[Amazon.EC2.Model.Vpc]
.INPUTS
AWS VPC from Get-EC2Vpc [Amazon.EC2.Model.Vpc]
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.AWS.VPC.Info
.EXAMPLE
Return a custom object from one VPC:
Get-EC2Vpc -VpcId vpc-77a1b77053c67aaaa | Show-EC2Vpc
.EXAMPLE
Return a custom object from two VPCs into a variable:
$myVar = Get-EC2Vpc -VpcId vpc-77a1b77053c67aaaa , vpc-77a1b77053c67bbbb  | Show-EC2Vpc
.EXAMPLE
Return a custom object from one VPC, converting the output to JSON:
$myVar = Get-EC2Vpc -VpcId vpc-77a1b77053c67aaaa | Show-EC2Vpc
$jVar = $myVar | Select-Object * -ExcludeProperty Object | ConvertTo-Json -Depth 4
.LINK
Get-EC2Vpc
#>

Function Show-EC2Vpc
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Amazon.EC2.Model.Vpc[]] $Vpc
    )

    Process
    {
        foreach ($vp in $vpc)
        {
            $dh = (Get-EC2VpcAttribute -VpcId $vp.vpcid -Attribute enableDnsHostnames).EnableDnsHostnames
            $ds = (Get-EC2VpcAttribute -VpcId $vp.vpcid -Attribute enableDnsSupport).EnableDnsSupport
            $vh = @{
                DnsHostNames = $dh
                DnsResolution = $ds
            }
            $lo = [aClass]::MakeVPCObj($vp , $vh)
            $lo
        }
    }
}