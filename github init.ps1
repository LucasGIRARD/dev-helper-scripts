# Define the base URL for GitHub repository creation
$baseUrl = "https://github.com/LucasGIRARD/"

# Get all directories in the current location
$directories = Get-ChildItem -Directory
$repos = gh repo list

foreach ($directory in $directories) {
    # Extract the first character of the directory name
    $firstChar = $directory.Name[0]

    # Skip directories starting with "_"
    if ($firstChar -ne "_") {
        # Replace spaces in the directory name with "-"
        $sanitizedDirName = $directory.Name.Replace(" ", "-")
        
        $notFound = $true
        foreach ($repo in $repos) {
            # Check if the repository already exists
            if ($repo -match $sanitizedDirName) {
                $notFound = $false
                break
            }
        }

        Write-Host "Repo $sanitizedDirName not exist: $notFound"

        if ($notFound) {

             # Change the current directory
            Set-Location -Path $directory.FullName

            # Check for existing directories and set a flag if found
            $htdFlag = $false
            if (Test-Path -Path "htdocs") { Set-Location -Path "htdocs"; $htdFlag = $true }
            if (Test-Path -Path "htdocs1") { Set-Location -Path "htdocs1"; $htdFlag = $true }
            
            # Create a new GitHub repository
            gh repo create $sanitizedDirName --private

            # Initialize Git repository
            git init

            # Add all files to the staging area
            git add .

            # Commit the changes
            git commit -m "Initial commit"

            git tag -a v1.0.0 -m "Initial commit"

            # Rename the master branch to main
            git branch -M main

            # Add a remote repository
            git remote add origin $baseUrl$sanitizedDirName.git

            # Pause for user input (optional)
            Read-Host -Prompt "Press enter to continue..."

            # Push changes to the remote repository
            git push -u origin main

            # Change back to the parent directory if htd flag was set
            if ($htdFlag) { Set-Location -Path ".."; $htdFlag = $false }
            Set-Location -Path ".."
            Read-Host -Prompt "Press enter to exit..."
        }
    }
}
Read-Host -Prompt "Press enter to exit..."