# Set variables
$csvFile = "D:\users.csv"
$group = ""

# Delete the header in the CSV file or delete the following line and -Header section on $users variable
$header = 'FullName','Username','Password'

# Import CSV file
$users = Import-CSV $csvFile -Delimiter ',' -Header $header

# Uncomment to test the user (row) count
# Write-Host $users.Count

# Loop through each row in the CSV file
foreach ($user in $users) {
$fullname = $user.FullName
# Uncomment and set a break to test if it shows the full name properly. Comma seperation is tricky.
# Write-Host $user
$username = $user.Username
$password = $user.Password

# Create new user
New-LocalUser -Name $username -Password (ConvertTo-SecureString -String $password -AsPlainText -Force) -FullName $fullname -PasswordNeverExpires:$true

# Add user to the specified group
Add-LocalGroupMember -Group $group -Member $username
}