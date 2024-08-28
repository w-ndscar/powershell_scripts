# This script finds the Last Bootup Time of the computers in a domain

# Retrieve a list of all Active Directory computers
$computers = Get-ADComputer -Filter *

# Create an empty array to hold the results
$results = @()

# Loop through each computer and run the Get-CimInstance command
foreach ($computer in $computers) {
    $result = Get-CimInstance -ClassName win32_operatingsystem -ComputerName $computer.Name | Select-Object csname, lastbootuptime
    $results += $result
}

# Export the results to a CSV file
# $results | Export-Csv -Path "C:\boottime.csv" -NoTypeInformation
