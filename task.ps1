$location = "swedencentral"
$resourceGroupName = "mate-azure-task-12"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"

# Чтение твоего ключа ed25519
$sshKeyPublicKey = Get-Content "$HOME/.ssh/id_ed25519.pub"

$publicIpAddressName = "linuxboxpip"
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_D2s_v3"
$dnsLabel = "matetask" + (Get-Random -Count 1)

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow;
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow;
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet

New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

# Для Швеции ставим Standard SKU и Static (иначе упадет)
New-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName -Location $location -Sku Standard -AllocationMethod Static -DomainNameLabel $dnsLabel

# Создание VM (запросит Credential, введи любой логин/пароль)
New-AzVm `
    -ResourceGroupName $resourceGroupName `
    -Name $vmName `
    -Location $location `
    -Image $vmImage `
    -Size $vmSize `
    -SubnetName $subnetName `
    -VirtualNetworkName $virtualNetworkName `
    -SecurityGroupName $networkSecurityGroupName `
    -SshKeyName $sshKeyName `
    -PublicIpAddressName $publicIpAddressName

# ВОТ ТВОЯ ПРЯМАЯ ССЫЛКА НА ФАЙЛ:
$scriptUrl = "https://github.com/goldbergnik1993-cloud/azure_task_12_deploy_app_with_vm_extention.git"

Set-AzVMExtension `
    -ResourceGroupName $resourceGroupName `
    -VMName $vmName `
    -Location $location `
    -Name "InstallWebApp" `
    -Publisher "Microsoft.Azure.Extensions" `
    -ExtensionType "CustomScript" `
    -TypeHandlerVersion "2.1" `
    -SettingString "{'fileUris': ['$scriptUrl'], 'commandToExecute': 'bash install-app.sh'}"

