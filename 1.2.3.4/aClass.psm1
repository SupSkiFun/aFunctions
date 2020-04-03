class aClass
{
    static [PSCustomObject] MakeEC2IObj ([psobject] $obj )
    {
        $lo = [pscustomobject]@{
            Name = ($obj.Tags |
                Where-Object {$_.Key -match "Name"}).Value
            ID = $obj.InstanceId
            PrivateIP = $obj.PrivateIpAddress
            PublicIP = $obj.PublicIpAddress
            PublicDNS = $obj.PublicDnsName
            Type = $obj.InstanceType.Value
            SecurityGroupName = $obj.SecurityGroups.GroupName
            SecurityGroupID = $obj.SecurityGroups.GroupId
            Tags = $obj.Tags
            State = $obj.State.Name
            SubnetID = $obj.SubnetId
            VpcID = $obj.VpcId
            Object = $obj
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.AWS.EC2Instance.Info')
        return $lo
    }

    static [PSCustomObject] MakeVPCObj ([psobject] $obj , [hashtable] $exh )
    {
        $lo = [pscustomobject]@{
            Name = ($obj.Tags |
                Where-Object {$_.Key -match "Name"}).Value
            CidrBlock = $obj.CidrBlock
            VpcID = $obj.VpcId
            DhcpOptionsId = $obj.DhcpOptionsId
            IsDefault = $obj.IsDefault
            State = $obj.State.Value
            OwnerId = $obj.OwnerId
            DnsHostNames = $exh.'DnsHostNames'
            DnsResolution = $exh.'DnsResolution'
            Object = $obj
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.AWS.VPC.Info')
        return $lo
    }
}