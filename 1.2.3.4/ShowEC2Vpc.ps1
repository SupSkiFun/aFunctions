using module .\aClass.psm1   #  Remove This!

Function Show-EC2VPC
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
            $lo = [aClass]::MakeVPCObj( $vp , $vh )    # Fix this!
            $lo
        }
    }
}








