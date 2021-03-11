Class Route53HotRod
{
    static $Type = 'A'

    static [pscustomobject] MakeR53Obj ([psobject] $rs)
    {
        $lo = [pscustomobject]@{
            FQDN = $rs.Name
            IP = $rs.ResourceRecords.Value
            Type = $rs.Type
            TTL = $rs.TTL
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.AWS.R53.Record.Info')  
        return $lo
    }
    
    static [pscustomobject] MakeR53Obj ([psobject] $rc, [psobject] $rv, [string] $HostedZoneId)
    {
        $lo = [pscustomobject]@{
            FQDN = $rc.ResourceRecordSet.Name
            IP = $rc.ResourceRecordSet.ResourceRecords.Value
            Action = $rc.Action
            Type = $rc.ResourceRecordSet.Type
            TTL = $rc.ResourceRecordSet.TTL
            ZoneID = $HostedZoneId
            JobID = $rv.ID
            Status = $rv.Status
            SubmittedAt = $rv.SubmittedAt
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.AWS.R53.A.Record.Info') 
        return $lo
    }
    
    static [psobject] MakeR53Change ([string] $Action, [psobject] $rr)
    {
        $rc = [Amazon.Route53.Model.Change]::new()
        $rc.Action = $Action
        $rc.ResourceRecordSet = $rr
        return $rc
    }    

    static [psobject] MakeR53ResRec ([string] $FQDN, [Int32] $TTL, [ipaddress] $IP)
    {
        $rr = [Amazon.Route53.Model.ResourceRecordSet]::new()
        $rr.Name = $FQDN
        $rr.Type = [Route53HotRod]::Type
        $rr.TTL = $TTL
        $rr.ResourceRecords.Add(@{Value = $IP})
        return $rr
    }
}

Function Set-R53ARecord
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("CREATE", "DELETE")]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [string] $FQDN,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $HostedZoneId,

        [Parameter(Mandatory = $true)]
        [ipaddress] $IP,

        [Parameter(Mandatory = $false)]
        [Int32] $TTL = 300
    )

    Process
    {
        $rr = [Route53HotRod]::MakeR53ResRec($FQDN, $TTL, $IP)
        $rc = [Route53HotRod]::MakeR53Change($Action, $rr)
        $rv = Edit-R53ResourceRecordSet -HostedZoneId $HostedZoneId -ChangeBatch_Change $rc
        $lo = [Route53HotRod]::MakeR53Obj($rc, $rv , $HostedZoneId)
        $lo
    }
}

<#
.SYNOPSIS
Formats returned records from a Route 53 Hosted Zone.
.DESCRIPTION
Creates a PSCUSTOMOBJECT of returned records from a Route 53 Hosted Zone.
The custom object is much easier to view and work with.
.NOTES
The Get-R53ResourceRecordSet has a MaxLimit parameter that might need adjusting for large zones.
.PARAMETER RecordSets
Mandatory. Output from AWS Get-R53ResourceRecordSet (Module: AWS.Tools.Route53). See Examples.
[Amazon.Route53.Model.ListResourceRecordSetsResponse]
.INPUTS
AWS Route 53 Records from Get-R53ResourceRecordSet
[Amazon.Route53.Model.ListResourceRecordSetsResponse]
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.AWS.R53.Record.Info
.EXAMPLE
Please Read.

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org" 

Second:  Using a specific zone, retrieve records putting them into a pscustomobject.
$myVar = Get-R53ResourceRecordSet -HostedZoneId $myZone.Id | Show-R53Record 
.EXAMPLE
Slightly different, piping the zone:

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org" 

Second:  Using a specific zone, retrieve records putting them into a pscustomobject.
$myVar = $myZone | Get-R53ResourceRecordSet  | Show-R53Record
.EXAMPLE
HostedZoneID can be submitted manually if preferred:

$myVar = Get-R53ResourceRecordSet -HostedZoneId '/hostedzone/BigOldStringOfChars' | Show-R53Record 
.LINK
Get-R53HostedZoneList
Get-R53ResourceRecordSet
#>

Function Show-R53Record
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Amazon.Route53.Model.ListResourceRecordSetsResponse] $RecordSets
    )

    Process
    {
        foreach ($rr in $RecordSets.ResourceRecordSets)
        {
            $lo = [Route53HotRod]::MakeR53Obj($rr)
            $lo
        }
    }
}