# This script gets the system info of the computers in a Domain (PC Name, Manufacturer, Model Number, Serial Number, Windows Key, Windows Digital Key, CPU, Memory, Disks and their types and capacity)
# This script can also be used to get the system info of an individual computer


# Function to extract and decode the Windows product key
Function Get-WindowsKey {
    $key = ''
    $path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $regValue = (Get-ItemProperty $path).DigitalProductId[52..66]
    $chars = 'BCDFGHJKMPQRTVWXY2346789'
    For ($i = 24; $i -ge 0; $i--) {
        $r = 0
        For ($j = 14; $j -ge 0; $j--) {
            $r = ($r * 256) -bxor $regValue[$j]
            $regValue[$j] = [math]::Floor([double]($r/24))
            $r = $r % 24
        }
        $key = $chars[$r] + $key
        If (($i % 5) -eq 0 -and $i -ne 0) {
            $key = "-" + $key
        }
    }
    $key
}

# Main Block
$scriptBlock = {
    # Get and store the values
    $computerSystem = Get-CimInstance -Class Win32_ComputerSystem
    $sysinfo = Get-CimInstance -Class Win32_BIOS
    $one_gb = 1024*1024*1024

    $pc_name = $computerSystem | Select-Object -ExpandProperty Name
    $manufacturer = $computerSystem | Select-Object -ExpandProperty Manufacturer
    $model = $computerSystem | Select-Object -ExpandProperty Model

    # CPU
    $CPU_obj = Get-CimInstance -Class Win32_Processor
    $CPU = $CPU_obj | Select-Object -ExpandProperty Name

    # GPU
    $GPU_obj = @(Get-CimInstance -Class Win32_VideoController)
    $GPU_Names = @()
    $GPU_VRAMs = @()
    for ($i = 0; $i -lt $GPU_obj.Count; $i++) {
        if ($GPU_obj[$i].Name -eq '') {
            $GPU_obj[$i].Name = 'No GPU Detected'
        }
        else {
            $GPU_Names += $GPU_obj[$i].Name
            $GPU_VRAMs += $GPU_obj[$i].AdapterRAM
            $GPU_VRAMs[$i] = $GPU_VRAMs[$i] / $one_gb
            $GPU_VRAMs[$i] = [Math]::Round($GPU_VRAMs[$i], 2)
        }
    }

    # Memory
    $memory = $computerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
    $memory = $memory/$one_gb
    $memory = [Math]::Round($memory, 0)

    # Disk
    $disk_obj = @(Get-PhysicalDisk)
    $disks = @()
    $disktypes = @()
    $size = @()
    for ($i = 0; $i -lt $disk_obj.Count; $i++)
    {
        if ($disk_obj.Count -eq 0) {
                $disks = $disk_obj.FriendlyName
                $disktypes = $disk_obj.MediaType
                $size_gb = $disk_obj.Size / $one_gb
                $size_gb = [Math]::Round($size_gb, 2)
                if ($size_gb -ge 900) {
                    $size_gb = 1000
                } elseif ($size_gb -gt 470) {
                    $size_gb = 512
                } elseif ($size_gb -lt 460) {
                    $size_gb = 480
                } else {
                    $size_gb = 500
                }
                $size += $size_gb
        }
        else {
            $disks += $disk_obj[$i].FriendlyName
            $disktypes += $disk_obj[$i].MediaType
            $size_gb = $disk_obj[$i].Size / $one_gb
            $size_gb = [Math]::Round($size_gb, 2)
            if ($size_gb -ge 900) {
                $size_gb = 1000
            } elseif ($size_gb -gt 470) {
                $size_gb = 512
            } elseif ($size_gb -lt 460) {
                $size_gb = 480
            } else {
                $size_gb = 500
            }
            $size += $size_gb
        }
    }

    # Serial and Win Key
    $serial = $sysinfo | Select-Object -ExpandProperty SerialNumber
    $wkey = (Get-WmiObject -query "select * from SoftwareLicensingService").OA3xOriginalProductKey
    
    # Getting Windows product key
    $windowsKey = Get-WindowsKey

    # A custom object
    $result = [PSCustomObject]@{
        PC_Name = $pc_name
        Manufacturer = $manufacturer
        Model_Number = $model
        Serial_Number = $serial
        Windows_Key = $windowsKey
        Win_Key_WMIC = $wkey
        CPU = $CPU
        GPU = $GPU_Names
        GPU_VRAM = $GPU_VRAMs
        Memory = $memory
        Disk = $disks
        Disk_Type = $disktypes
        Disk_Size = $size
    }

    return $result
}

# Get the list of computer names from AD
# Comment out the lines below if you want to get the system info of an individual PC
$OUs = 'OU=OrganisationalUnit, DC=domain, DC=com', 'OU=AnotherOrganisationalUnit, DC=domain, DC=com'
$computerNames = @()
$computerNames = $OUs | ForEach-Object {
    Get-ADComputer -Filter * -SearchBase $_ | Select-Object -ExpandProperty Name
}

# Uncomment the following lines below if you want to get the system info of an individual PC
# $computerSystem = Get-CimInstance -Class Win32_ComputerSystem
# $computerNames = $computerSystem.Name

# Initialize an array to hold the results
$results = @()

# Loop through each computer and execute the script block
foreach ($computer in $computerNames) {
    Write-Host "Processing $computer..."
    $result = Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock -ErrorAction SilentlyContinue
    if ($result) {
        $results += $result
        # $result | Export-Csv -Path $excelFilePath -Append
    } else {
        Write-Host "Failed to get data from $computer"
    }
}

# Convert to JSON and Write the Output
$time = (Get-Date).ToString("yyyyMMdd_HHmmss")
$results | ConvertTo-Json | Set-Content -Path ".\sysinfo_output_$time.json"

Write-Host $results
