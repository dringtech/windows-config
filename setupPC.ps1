Get-ExecutionPolicy -Scope CurrentUser
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$configFile = $Args[0]

Get-Content $configFile | foreach-object -begin {$config=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $config.Add($k[0], $k[1]) } }

Write-Output $config

# Set up admin user
$AdminPass = $config.adminPassword | ConvertTo-SecureString -AsPlainText -Force
New-LocalUser $config.adminUser -Password $AdminPass
Set-LocalUser $config.adminUser -Password $AdminPass -FullName "Tech Support" -Description "Tech Support Account"
Add-LocalGroupMember -Group "Administrators" -Member $config.adminUser

if ($env:USERNAME -ne $config.initialUser) {
  Remove-LocalUser $config.initialUser
}

Start-Service w32time
w32tm /register