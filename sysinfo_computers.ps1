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

    $pc_name = $computerSystem.Name
    $manufacturer = $computerSystem.Manufacturer
    $model = $computerSystem.Model

    # CPU
    $CPU = Get-CimInstance -Class Win32_Processor
    $CPU = $CPU.Name

    # Memory
    #$memory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1gb
    $memory = $computerSystem.totalPhysicalMemory
    $memory = $memory/$one_gb
    $memory = [Math]::Round($memory, 2)

    # Disk
    $disk = Get-PhysicalDisk
    $diskname = $disk.FriendlyName
    $disktype = $disk.MediaType
    $disk_size = $disk.Size
    $disk_size = $disk_size/$one_gb
    $disk_size = [Math]::Round($disk_size, 2)

    # Serial and Win Key
    $serial = $sysinfo.SerialNumber
    $wkey = (Get-WmiObject -query "select * from SoftwareLicensingService").OA3xOriginalProductKey
    $wkey | Out-String


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
        Memory = $memory
        Disk = $diskname
        Disk_Type = $disktype
        Disk_Size = $disk_size
    }

    return $result
}

# Get the list of computer names from AD
# Comment out the line below if you want to get the system info of an individual PC
$computerNames = Get-ADComputer -Filter * -SearchBase 'OU=OrganisationalUnit, DC=domain, DC=com' -Property Name | Select-Object -ExpandProperty Name

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
$results | ConvertTo-Json
Write-Host $results

# Export the results to a CSV(.csv)/Excel(.xlsx)

# Path to store the exported files
# $csvPath = "path\to\out.csv"
# $excel2path = "path\to\out2.xlsx"

# Export to CSV and XLSX
# $results | Export-Csv -Path $csvPath -NoTypeInformation
# $results | Export-Excel -Path $excel2path # ImportExcel Module is needed for this to work
# Write-Host "Data exported to CSV and Excel files at $excelFilePath and $excel2path"
