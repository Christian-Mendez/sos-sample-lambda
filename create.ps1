#This is a simple script to create snapshots in aws
#Requires -Modules @{ModuleName='AWSPowerShell.NetCore';ModuleVersion='3.3.283.0'}

#Get EC2 instances where the backup tag value is true
$filter = @{name='tag:backup'; values="true"}
$instances = Get-EC2instance -filter $filter

foreach ($instance in $instances){
    
    $this_instance = $instance.Instances
    Write-Host $this_instance.InstanceID -ForegroundColor Magenta
    foreach ($volume in ($this_instance.BlockDeviceMappings)){
    
        $tag1 = New-Object Amazon.EC2.Model.Tag
        $tag1.Key = "device-name"
        $tag1.Value = $volume.DeviceName
    
        $tag2 = New-Object Amazon.EC2.Model.Tag
        $tag2.Key = "volume-size"
        $tag2.Value = Get-EC2Volume -VolumeId $volume.ebs.VolumeId | Select-Object Size -ExpandProperty Size
    
        $tag3 = New-Object Amazon.EC2.Model.Tag
        $tag3.Key = "availability-zone"
        $tag3.Value = Get-EC2Volume -VolumeId $volume.ebs.VolumeId | Select-Object AvailabilityZone -ExpandProperty AvailabilityZone
    
        $tag4 = New-Object Amazon.EC2.Model.Tag
        $tag4.Key = "volume-type"
        $tag4.Value = Get-EC2Volume -VolumeId $volume.ebs.VolumeId | Select-Object VolumeType -ExpandProperty VolumeType
    
        $tag5 = New-Object Amazon.EC2.Model.Tag
        $tag5.Key = "iops"
        $tag5.Value = Get-EC2Volume -VolumeId $volume.ebs.VolumeId | Select-Object Iops -ExpandProperty Iops
    
        $tagspec1 = new-object Amazon.EC2.Model.TagSpecification
        $tagspec1.ResourceType = "Snapshot"
        $tagspec1.Tags.Add($tag1)
        $tagspec1.Tags.Add($tag2)
        $tagspec1.Tags.Add($tag3)
        $tagspec1.Tags.Add($tag4)
        $tagspec1.Tags.Add($tag5)
    
        $volume_description = "Automated snapshot of "+$volume.DeviceName+" for instance: "+$this_instance.InstanceID
        $volume.ebs | New-EC2Snapshot -TagSpecification $tagspec1 -Description $volume_description
    
    }
}

# Publush this script to lambda with the following command
# Publish-AWSPowerShellLambda -ScriptPath .\snapshots.ps1 -Name Snapshots -Region us-east-1