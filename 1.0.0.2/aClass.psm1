class aClass
{
    static [PSCustomObject] MakeSEC2IObj ([psobject] $obj )
    {
        $lo = [pscustomobject]@{
            Name = ($obj.Instances.Tags |
                Where-Object {$_.Key -match "Name"}).Value
            ID = $obj.instances.InstanceId
            PrivateIP = $obj.Instances.PrivateIpAddress
            PublicIP = $obj.Instances.PublicIpAddress
            PublicDNS = $obj.Instances.PublicDnsName
            Type = $obj.Instances.InstanceType.Value
            SecurityGroupName = $obj.Instances.SecurityGroups.GroupName
            SecurityGroupID = $obj.Instances.SecurityGroups.GroupId
            Tags = $obj.Instances.Tags
            State = $obj.Instances.State.Name
            SubnetID = $obj.Instances.SubnetId
            VpcID = $obj.Instances.VpcId
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.AWS.EC2Instance.Info')
        return $lo
    }
}