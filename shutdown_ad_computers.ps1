# Prompt for domain admin credentials
$cred = Get-Credential -Message "Enter domain admin credentials"

# Get all computers in the AD domain
$computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

# Shut down all computers in the domain using domain admin credentials
foreach ($computer in $computers) {
    Stop-Computer -ComputerName $computer -Credential $cred -Force
}
