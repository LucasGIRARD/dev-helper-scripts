$options = @("web", "all", "php debug", "mysql")

function Select-Option {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Options
    )

    $selectedIndex = 0
    $previousIndex = -1

    while ($true) {
        if ($previousIndex -ne $selectedIndex) {
            Clear-Host
            for ($i = 0; $i -lt $Options.Length; $i++) {
                if ($i -eq $selectedIndex) {
                    Write-Host "> $($Options[$i])"
                } else {
                    Write-Host " $($Options[$i])"
                }
            }
            $previousIndex = $selectedIndex
        }

        $keyInfo = [Console]::ReadKey($true)
        if ($keyInfo.Key -eq 'UpArrow') {
            if ($selectedIndex -gt 0) {
                $selectedIndex--
            }
        } elseif ($keyInfo.Key -eq 'DownArrow') {
            if ($selectedIndex -lt ($Options.Length - 1)) {
                $selectedIndex++
            }
        } elseif ($keyInfo.Key -eq 'Enter') {
            break
        }
    }

    Clear-Host
    return $selectedIndex
}

$selectedIndex = Select-Option -Options $options
#Write-Host "You selected: $($options[$selectedIndex])"
cd C:\devilbox
if ($($options[$selectedIndex]) -eq 'web') {
    docker-compose up httpd php mysql mailhog
} elseif ($($options[$selectedIndex]) -eq 'all') {
    docker-compose up
} elseif ($($options[$selectedIndex]) -eq 'mysql') {
    docker-compose up mysql
} elseif ($($options[$selectedIndex]) -eq 'php debug') {
    docker-compose up httpd php mysql blackfire
}

docker-compose rm -f