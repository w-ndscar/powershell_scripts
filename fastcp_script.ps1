# Set the source and destination paths
$sourcePath = "source_path"
$destinationPath = "dest_path"

# Create a new folder on the destination path with the current month and day as the name of the folder in the format "MMM-d"
$newFolderName = Get-Date -Format "MMM-d"
$newFolderPath = Join-Path $destinationPath $newFolderName
New-Item -ItemType Directory -Path $newFolderPath

# Set the FastCopy command with the required options
$fastCopyCommand = "C:\Fastcopy\fcp.exe /cmd=diff /speed=full /no_confirm_stop /force_start `"$sourcePath`" /to=`"$newFolderPath`""

# Set the log file path
$logFilePath = "C:\log\fastcopy.log"

# Run the FastCopy command and append the log to the log file
# Invoke-Expression "$fastCopyCommand > `"$logFilePath`" 2>&1"

# Run the FastCopy command and append the log to the log file
Invoke-Expression $fastCopyCommand | Out-File -FilePath $logFilePath -Append
