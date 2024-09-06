# Set variables
$csvFile = "D:\local_users.csv"
$group = ""

# Import CSV file
$users = Import-Csv $csvFile

# Loop through each user in CSV file
foreach ($user in $users) {
# Set username and password
$username = $user.username
$password = $user.password
$fullname = $user.FullName

# Create new user
$userObj = New-LocalUser -Name $username -Password (ConvertTo-SecureString -String $password -AsPlainText -Force) -FullName $fullname -PasswordNeverExpires:$true

# Add user to group
Add-LocalGroupMember -Group $group -Member $username
}