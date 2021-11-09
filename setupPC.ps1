# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$configFile = $Args[0]

if ($configFile -eq $null) {
  Write-Output "Please provide the path to a config file"
  exit
}

Try {
    Get-Content $configFile -ErrorAction Stop | foreach-object -begin {$config=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $config.Add($k[0], $k[1]) } }
} Catch {
    $_.message | Write-Error
    exit
}

Write-Output $config

# Set up admin user
$AdminPass = $config.adminPassword | ConvertTo-SecureString -AsPlainText -Force
Try {
    New-LocalUser $config.adminUser -Password $AdminPass -ErrorAction Stop
} Catch {
    $_ | Write-Warning
}
Set-LocalUser $config.adminUser -Password $AdminPass -FullName "Tech Support" -Description "Tech Support Account" -PasswordNeverExpires 1
Try {
    Add-LocalGroupMember -Group "Administrators" -Member $config.adminUser -ErrorAction Stop
} Catch {
    $_ | Write-Warning 
}

# Set up main user
$UserPass = $config.mainPassword | ConvertTo-SecureString -AsPlainText -Force
Try {
    New-LocalUser $config.mainUser -Password $UserPass -ErrorAction Stop
} Catch {
    $_ | Write-Warning   
}
Set-LocalUser $config.mainUser -Password $UserPass -FullName $config.mainName -Description $config.mainDescription -PasswordNeverExpires 1
if ($config.mainIsAdmin -eq "true") {
    Try {
        Add-LocalGroupMember -Group "Administrators" -Member $config.mainUser -ErrorAction Stop
    } Catch {
        $_ | Write-Warning
    }
}

if ($env:USERNAME -ne $config.initialUser) {
    Try {
        Remove-LocalUser $config.initialUser -ErrorAction Stop
    } Catch {
        $_ | Write-Warning
    }
}

Start-Service w32time
w32tm /register