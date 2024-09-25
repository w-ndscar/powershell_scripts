# Set the number of days of inactivity before an account is considered inactive
$InactiveDays = 60

# Get the current date
$CurrentDate = Get-Date

# Find inactive user accounts
$InactiveUsers = Search-ADAccount -AccountInactive -TimeSpan "$InactiveDays" -UsersOnly | Where-Object { $_.Enabled -eq $true }

# Find inactive computer accounts
$InactiveComputers = Search-ADAccount -AccountInactive -TimeSpan "$InactiveDays" -ComputersOnly | Where-Object { $_.Enabled -eq $true }

$InactiveUsers | Select-Object Name, SamAccountName, Enabled, LastLogonDate | export-csv C:\InactiveADEntries\After\LastLogOn_Users.csv -notypeinformation

$InactiveComputers | Select-Object Name, SamAccountName, Enabled, LastLogonDate | export-csv C:\InactiveADEntries\After\LastLogOn_Computers.csv -notypeinformation

# Delete inactive user accounts
foreach ($User in $InactiveUsers) {
    Remove-ADUser -Identity $User -Confirm:$false
}

# Delete inactive computer accounts
foreach ($Computer in $InactiveComputers) {
    Remove-ADComputer -Identity $Computer -Confirm:$false
}
