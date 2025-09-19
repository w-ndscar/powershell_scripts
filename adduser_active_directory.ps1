# Load Active Directory module
Import-Module ActiveDirectory

# Set variables
$csvFile = "D:\users.csv"
$group = ""

# Delete the header in the CSV file or delete the following line and -Header section on $users variable
$header = 'FirstName','LastName','Username','Password','Group'

# Import CSV file
$users = Import-CSV $csvFile -Delimiter ',' -Header $header

# Loop through each row in the CSV file
foreach ($user in $users) {
    $Name = "$($user.FirstName) $($user.LastName)"
    $SamAccountName = $user.Username
    $Group = $user.Group
    $Password = (ConvertTo-SecureString -String $user.Password -AsPlainText -Force)

    try {
        # Create new user
        New-ADUser -Name $Name -GivenName $user.FirstName -Surname $user.LastName -SamAccountName $SamAccountName -AccountPassword $Password -Enabled $true -PasswordNeverExpires $true
        Write-Host "Created user: $Name with username: $SamAccountName"
        # Add user to the specified group
        Add-ADGroupMember -Identity $Group -Members $SamAccountName
        Write-Host "Added user: $Name to group: $Group"
    }
    catch {
        Write-Host "Error creating user: $Name. $_"
    }
    
}