using module ./aClass.psm1
<#
.SYNOPSIS
Removes S3 Object Versions that are not current; retains specified least old versions.
.DESCRIPTION
Removes S3 Object Versions that are not current; retains specified least old versions.  See Notes.
.NOTES
1) Applies to ALL non-current object versions within the specified bucket.
2) Only old versions are removed.  Current version is not removed.
3) Parameter -Retain is optional.  Default is 2.  Specifies least old versions to retain.
4) Terminates if versions aren't obtained from the specified bucket.
5) Terminates if no versions are found to remove.
6) -WhatIf Parameter reflects key and version ID joined by a '~'.
7) Not tested with large volumes of objects and versions.
.PARAMETER BucketName
[String] Name of the Bucket - Mandatory
.PARAMETER Retain
[UInt16] Number of least old versions to retain.  Default is 2.  Alias Keep.  See Notes.
.INPUTS
See Parameters.
.OUTPUTS
Amazon.S3.Model.DeleteObjectsResponse or a termination message.
.EXAMPLE
Purge all old versions,  excepting current version and least oldest 2:

Remove-S3Version -BucketName mybucket
.EXAMPLE
Purge all old versions,  excepting current version and least oldest 3:

Remove-S3Version -BucketName mybucket -Retain 3
#>

function Remove-S3Version {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="high")]
    param (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [String] $BucketName,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [Alias("Keep")]
        [UInt16] $Retain=2
    )

    begin {
        try {
            $allvers=Get-S3Version -BucketName $BucketName
        }
        catch {
            $m="Terminating. Error Listing Versions from Bucket $BucketName.`n"
            Write-Output $m
            Write-Output $_
            break
        }
    }

    process {
        $oldvers=$allvers.Versions |
            Where-Object -Property IsLatest -eq $false |
            Group-Object -Property Key |
            Where-Object -Property Count -gt $Retain
        $delvers=foreach ($o in $oldvers) {
            $o.Group |
            Sort-Object -Property LastModified -Descending |
            Select-Object -Property Key, VersionId, Etag -Skip $Retain
        }
        if (-not $delvers) {
            $m="Terminating. No Versions to Remove from Bucket $BucketName."
            Write-Output $m
            break
        }
        $arrkill=[System.Collections.Generic.List[object]]::new()
        <# $arrproc for -WhatIf info formatted #>
        $arrproc=[System.Collections.Generic.List[object]]::new()
        foreach ($d in $delvers) {
            <# had to make a new $nobj each time; couldn't overwrite #>
            $nobj=[Amazon.S3.Model.KeyVersion]::new()
            $nobj.Key=$d.key
            $nobj.VersionId=$d.VersionId
            $nobj.ETag=$d.ETag
            $arrkill.Add($nobj) | Out-Null
            <# $arrproc for -WhatIf info formatted #>
            $arrproc.Add($($d.Key, $d.VersionId -join "~")) | Out-Null
        }
        if ($PSCmdlet.ShouldProcess($($arrproc))) {
            $parms=@{
                BucketName=$BucketName
                KeyAndVersionCollection=$arrkill
                Confirm=$false
            }
            try {
                Remove-S3Object @parms
            }
            catch {
                $m="Terminating. Error Removing Versions from $BucketName.`n"
                Write-Output $m
                Write-Output $_
                break
            }
        }
    }
}

<#
.SYNOPSIS
Creates or Deletes a Route 53 Alias A Record that points to an Elastic Load Balancer.
.DESCRIPTION
Creates or Deletes a Route 53 Alias A Record that points to an Elastic Load Balancer.
Application and Network Load Balancers are supported.  Classic Load Balancers are not supported.
.NOTES
1) Read the Example.
2) Requires an ELBv2 Object either piped in or supplied to parameter LoadBalancer.qq
[Amazon.ElasticLoadBalancingV2.Model.LoadBalancer]
.PARAMETER Action
Mandatory. Either CREATE or DELETE.
.PARAMETER Evaluate
Optional. Boolean to select whether to Evaluate Target Health or not.
Defaults to $true. Parameter Alias EvaluateTargetHealth.
.PARAMETER FQDN
Mandatory. Fully Qualified Domain Name to Alias to the Load Balancer DNS Name.
.PARAMETER LoadBalancer
Mandatory. [Amazon.ElasticLoadBalancingV2.Model.LoadBalancer] Object. Either an ALB or NLB.
.PARAMETER ZoneId
Mandatory. The Route 53 Zone to host the new Alias Record.
.INPUTS
Amazon.ElasticLoadBalancingV2.Model.LoadBalancer
.OUTPUTS
Amazon.Route53.Model.ChangeInfo
.EXAMPLE
Please Read:

1) Obtain required information:

$r53 = (Get-R53HostedZonesByName -DNSName example.com).Id
$alb = (Get-ELB2LoadBalancer).where({$_.LoadBalancerName -eq "test-alb"})
$fqdn = "test04.example.com"

2) Create a record:

$resp = $alb | Set-ELB2Alias -Action CREATE -FQDN $fqdn -ZoneID $r53 -WhatIf

3) Optionally check the status of the record:

Get-R53Change $resp.id

Status PENDING - record is being processed.
Status INSYNC - record successfully processed.

4) Optionally check the value of a DNS request to Route 53:

Test-R53DNSAnswer -HostedZoneId $($r53.split("/")[-1]) -RecordName $fqdn -RecordType A

5) Optionally delete the record:

$resp2 = $alb | Set-ELB2Alias -Action DELETE -FQDN $fqdn -ZoneID $r53
#>

function Set-ELB2Alias {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="high")]

    param (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateSet("CREATE", "DELETE")]
        [string] $Action,

        [Parameter(Mandatory=$false)]
        [Alias("EvaluateTargetHealth")]
        [boolean] $Evaluate=$true,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $FQDN,

        [Parameter(Mandatory=$True, ValueFromPipeline=$true)]
        [Amazon.ElasticLoadBalancingV2.Model.LoadBalancer] $LoadBalancer,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $ZoneID
    )

    begin {
        $Type=[aClass]::Type   # Route53 Record Type
    }

    process {
        function MakeR53AliasTarget {
            param($LoadBalancer, $Evaluate)
            $aliastarget=[Amazon.Route53.Model.AliasTarget]::new()
            $aliastarget.DNSName=$LoadBalancer.DNSName
            $aliastarget.EvaluateTargetHealth=$Evaluate
            $aliastarget.HostedZoneId=$LoadBalancer.CanonicalHostedZoneId
            return $aliastarget
        }

        function MakeR53ResourceRecordSet {
            param($AliasTarget, $FQDN)
            $r53recset=[Amazon.Route53.Model.ResourceRecordSet]::new()
            $r53recset.AliasTarget=$AliasTarget
            $r53recset.Name=$FQDN
            $r53recset.Type=$Type
            return $r53recset
        }

        function MakeR53Change {
            param($Action, $R53RecSet)
            $r53change=[Amazon.Route53.Model.Change]::new()
            $r53change.Action=$Action
            $r53change.ResourceRecordSet=$R53RecSet
            return $r53change
        }

        $atparm=@{
            LoadBalancer=$LoadBalancer ;
            Evaluate=$Evaluate
        }
        $aliastarget=MakeR53AliasTarget @atparm

        $rsparm=@{
            AliasTarget=$aliastarget ;
            FQDN=$FQDN
        }
        $r53recset=MakeR53ResourceRecordSet @rsparm

        $r53change=MakeR53Change -Action $Action -R53RecSet $r53recset

        $erparm=@{
            HostedZoneId=$ZoneID ;
            ChangeBatch_Change=$r53change
        }

        if ($PSCmdlet.ShouldProcess("$($LoadBalancer.LoadBalancerArn)")) {
            Edit-R53ResourceRecordSet @erparm
        }
    }
}

<#
.SYNOPSIS
Creates or Deletes A records from a Route 53 Hosted Zone.
.DESCRIPTION
Creates or Deletes A records from a Route 53 Hosted Zone.  No other record types are supported.
Returns a pscustomobject for each record action, including submitted and returned information.
.NOTES
1. To delete a record, it is necessary to EXACTLY match the existing record, including TTL.
2. Show-R53Record can be piped into Set-R53ARecord to assist with deletions.  See Examples.
3. Record creation is limited to the parameters listed.  For more complex creations see Edit-R53ResourceRecordSet.
.PARAMETER Action
Mandatory. CREATE or DELETE.
.PARAMETER FQDN
Mandatory. Fully qualified name of the A record.  Example: myhost.mydomain.org
.PARAMETER HostedZoneId
Mandatory. AWS Zone ID of the record to create or delete.
.PARAMETER IP
Mandatory. IPv4 Address of the A record.  Example:. 10.10.10.10
.PARAMETER TTL
Optional. Time in seconds until cache expiration.  Defaults to 300 if no other value is specified.
.INPUTS
For deletion, output from Show-R53Record can be piped.  See Examples.
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.AWS.R53.A.Record.Info
.EXAMPLE
Create an A record:

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org"

Second:
$myVar = Set-R53ARecord -Action CREATE -FQDN bogus3.myDomain.org -IP 172.17.21.23 -HostedZoneId $myZone.Id
.EXAMPLE
Delete an A record:

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org"

Second:
$myVar = Set-R53ARecord -Action DELETE -FQDN bogus3.myDomain.org -IP 172.17.21.23 -HostedZoneId $myZone.Id
.EXAMPLE
Delete an A record using information from Show-R53Record:

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org"

Second:  Retrieve / Process A records from a Specific Zone:
$myInfo = $myZone | Get-R53ResourceRecordSet  | Show-R53Record

Third:  Query for a specific record:
$myRecord = $myInfo | Where-Object -Property FQDN -Match "bogus3"

Fourth:  Delete the record
$myVar = $myRecord | Set-R53ARecord -Action DELETE -HostedZoneId $myZone.Id
#>

Function Set-R53ARecord
{
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "High")]

    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("CREATE", "DELETE")]
        [string] $Action,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $FQDN,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $HostedZoneId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ipaddress] $IP,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Int32] $TTL = 300
    )

    Process
    {
        if ($pscmdlet.ShouldProcess($FQDN, $Action))
        {
            $rr = [aClass]::MakeR53ResRec($FQDN, $TTL, $IP)
            $rc = [aClass]::MakeR53Change($Action, $rr)
            $rv = Edit-R53ResourceRecordSet -HostedZoneId $HostedZoneId -ChangeBatch_Change $rc
            $lo = [aClass]::MakeR53Obj($rc, $rv , $HostedZoneId)
            $lo
        }
    }
}

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
Returns a decoded IAM Policy Document.
.DESCRIPTION
Returns a PSCUSTOMOBJECT of a decoded IAM Policy Document.
.NOTES
1. Requires System.Web.HttpUtility to decode the policy document.
2. DefaultDisplayPropertySet = "Document"
            To see all properties, issue either:
                $myVar | Format-List -Property *
                $myVar | Select-Object -Property *
.PARAMETER Policy
Mandatory. Output from AWS Get-IAMPolicyVersion (Module: AWS.Tools.IdentityManagement). See Examples.
[Amazon.IdentityManagement.Model.PolicyVersion]
.INPUTS
AWS IAM Policy from Get-IAMPolicyVersion [Amazon.IdentityManagement.Model.PolicyVersion]
.OUTPUTS
PSCUSTOMOBJECT SupSkiFun.AWS.IAMPolDoc.Info
.EXAMPLE
Please Read:

Return the IAM Policy Document Only (default display):
$myPol = Get-IAMPolicyVersion -PolicyArn arn:aws:iam::012345678901:policy/my_custom_policy -VersionId v1
$myVar = $myPol | Show-IAMPolicyDocument
$myVar
$myVar.Document
$myVar.Document | ConvertFrom-Json -Depth 12  | ConvertTo-Json -Depth 12
.EXAMPLE
Please Read:

Return the IAM Policy Document and related information (full display):
$myPol = Get-IAMPolicyVersion -PolicyArn arn:aws:iam::012345678901:policy/my_custom_policy -VersionId v3
$myVar = $myPol | Show-IAMPolicyDocument
$myVar | fl *
#>

Function Show-IAMPolicyDocument
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Amazon.IdentityManagement.Model.PolicyVersion] $Policy
    )

    Process
    {
        $pd = [System.Web.HttpUtility]::UrlDecode($policy.Document)
        $lo = [aclass]::MakeIAMDObj($policy, $pd)
        $lo
    }

    End
    {
        $TypeData = @{
            TypeName = 'SupSkiFun.AWS.IAMPolDoc.Info'
            DefaultDisplayPropertySet = "Document"
        }
        Update-TypeData @TypeData -Force
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
Retrieve and process records:

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org"

Second:  Using a specific zone, retrieve records putting them into a pscustomobject.
$myVar = Get-R53ResourceRecordSet -HostedZoneId $myZone.Id | Show-R53Record
.EXAMPLE
Retrieve and process records, piping the zone:

First:  Return Specific Zone into a variable:
$myZone = Get-R53HostedZoneList | Where-Object -Property Name -Match "myDomain.org"

Second:  Using a specific zone, retrieve records putting them into a pscustomobject.
$myVar = $myZone | Get-R53ResourceRecordSet  | Show-R53Record
.EXAMPLE
HostedZoneID can be submitted manually if preferred:

$myVar = Get-R53ResourceRecordSet -HostedZoneId '/hostedzone/BigOldStringOfChars' | Show-R53Record
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
            $lo = [aClass]::MakeR53Obj($rr)
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