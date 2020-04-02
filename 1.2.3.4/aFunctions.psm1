using module .\aClass.psm1

<#
.SYNOPSIS
Returns configuration information from EC2 Instances.
.DESCRIPTION
Returns a PSCUSTOMOBJECT of configuration information from EC2 Instances.
.NOTES
1) The Name NoteProperty will be empty if a name has not been specified.
2) Tags can be seen by returning the object into a variable (e.g. $myVar), then $myVar.Tags
3) Optimal JSON output is demonstrated in Example 4.
.PARAMETER EC2Instance
Mandatory. Output from AWS Get-EC2Instance (Module AWS.Tools.EC2). See Examples.
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
Return a custom object from all EC2 Instances in a region, including the source Object, into a variable:
$myVar = Get-EC2Instance -Region us-east-1 | Show-EC2Instance -IncludeObject
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
            $lo = [aClass]::MakeSEC2IObj($e)
            $lo
        }
    }
}