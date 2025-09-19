# Force-Restart computers in a domain

# Prompt for domain admin credentials
$cred = Get-Credential -Message "Enter domain admin credentials"

# Specify the OU to target (modify as needed)
$ou="OU=Workstations,DC=Organization,DC=com"

# Get all computers in the specified OU from the AD domain
$computers = (Get-ADComputer -SearchBase $ou) | Select-Object -ExpandProperty Name

# Shut down all computers in the domain using domain admin credentials
foreach ($computer in $computers) {
    Write-Host "Restarting $computer"
    Restart-Computer -ComputerName $computer -Credential $cred -Force -Verbose
}
