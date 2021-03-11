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
        return $lo
    }
    
    static [pscustomobject] MakeR53Obj ([psobject] $rc, [psobject]$rv, [string]$HostedZoneId)
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


<#
    Verb = submit or set?
    Require ZoneID = allow pipe type of HostedZoneId [string]
    Hard Code A
    ALLOW CREATE, DELETE - Parameter  -Action
   
    Allow TTL - set default of 300 [int32]
    Require FQDN [string]
    Require IP [ipaddress]
    Return object of input values + from AWS, ID, Status, SubmittedAt

$z = Get-R53HostedZoneList | ? name -match supskifun    # Use as an example in Help


    Seperate AF for Get - different input values required - different output values to produce


$ret = Edit-R53ResourceRecordSet -HostedZoneId $z.Id -ChangeBatch_Change $rec




DELETING
$rec.Action="DELETE"
Edit-R53ResourceRecordSet -HostedZoneId $z.Id -ChangeBatch_Change $rec


QUERYING

$sta = Get-R53Change -id $ret.id  (Where $ret is the return from a submitted request)

$z = Get-R53HostedZoneList | ? name -match supskifun    # Use as an example in Help
$dd = Get-R53ResourceRecordSet  -HostedZoneId $z.Id
$dd.ResourceRecordSets
$dd.ResourceRecordSets | select name, type
$dd.ResourceRecordSets.Where({$_.type -match A)}
$dd.ResourceRecordSets.Where({$_.type -match A})
$dd.ResourceRecordSets.Where({$_.type -match 'A'})
$dd.ResourceRecordSets.Where({$_.type -match 'A'}) | select name, resourcerecords
$ee = $dd.ResourceRecordSets.Where({$_.type -match 'A'}) | select name, resourcerecords
$ee[0].ResourceRecords
$ee[-1].ResourceRecords
USE THIS
$dd.ResourceRecordSets | select name, type, @{n="info";e={$_.ResourceRecords.Value}}
OR
$kk = $dd.ResourceRecordSets.Where({$_.type -eq 'A'}) | select name, type, @{n="info";e={$_.ResourceRecords.Value}}
STILL BETTER - CONVERTS TO JSON
$kk = $dd.ResourceRecordSets.Where({$_.type -eq 'A'}) | select Name, @{n="Type";e={$_.Type.Value}}, @{n="Info";e={$_.ResourceRecords.Value}},TTL

#>