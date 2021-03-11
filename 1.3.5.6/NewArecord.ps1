Class Route53Mod
{
    static $Type = 'A'

    static [psobject] MakeR53Change ([string] $Action , [psobject] $rr)
    {
        $rc = [Amazon.Route53.Model.Change]::new()
        $rc.Action=$Action
        $rc.ResourceRecordSet=$rr
        return $rc
    }    

    static [psobject] MakeResRecSet ([string] $FQDN, $TTL, $IP)
    {
        $rr= [Amazon.Route53.Model.ResourceRecordSet]::new()
        $rr.Name=$FQDN
        $rr.Type=[Route53Mod]::Type
        $rr.TTL = $TTL
        $rr.ResourceRecords.Add(@{Value=$IP})
        return $rr
    }

}

Function Set-R53ARecord
{
    [CmdletBinding()]

    Param
    (

        [Parameter(Mandatory=$true)]
        [ValidateSet("CREATE", "DELETE")]
        [string] $Action,

        [Parameter(Mandatory=$true)]
        [string] $FQDN,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $HostedZoneId,

        [Parameter(Mandatory=$true)]
        [ipaddress] $IP
    )

    Process
    {
        foreach ($e in $EC2Instance.Instances)
        {
            $lo = [aClss]::MakeEC2IObj($e)
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

#>
$ret = Edit-R53ResourceRecordSet -HostedZoneId $z.Id -ChangeBatch_Change $rec


<#

DELETING
$rec.Action="DELETE"
Edit-R53ResourceRecordSet -HostedZoneId $z.Id -ChangeBatch_Change $rec


QUERYING

$sta = Get-R53Change -id $ret.id  (Where $ret is the return from a submitted request)


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
$kk = $dd.ResourceRecordSets.Where({$_.type -eq 'A'}) | select Name, @{n="Type";e={$_.Type.Value}}, @{n="Info";e={$_.ResourceRecords.Value}}

#>