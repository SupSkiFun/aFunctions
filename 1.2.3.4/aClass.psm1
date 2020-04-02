class aClass
{
    static [PSCustomObject] MakeSEC2IObj ([psobject] $obj )
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
}