# Define the Docker Desktop executable path
$dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
$options = @("web", "mysql", "web+mailHog", "web+blackFire", "all")

trap {
    Write-Host "Caught Ctrl+C Press any key to continue..."
    $null = Read-Host
}

function Set-WindowState {
    <#
    .SYNOPSIS
    Set the state of a window.

    .DESCRIPTION
    Set the state of a window using the `ShowWindowAsync` function from `user32.dll`.

    .PARAMETER InputObject
    The process object(s) to set the state of. Can be piped from `Get-Process`.

    .PARAMETER State
    The state to set the window to. Default is 'SHOW'.

    .PARAMETER SuppressErrors
    Suppress errors when the main window handle is '0'.

    .PARAMETER SetForegroundWindow
    Set the window to the foreground

    .PARAMETER ThresholdHours
    The number of hours to keep the window handle in memory. Default is 24.

    .EXAMPLE
    Get-Process notepad | Set-WindowState -State HIDE -SuppressErrors

    .EXAMPLE
    Get-Process notepad | Set-WindowState -State SHOW -SuppressErrors

    .LINK
    https://gist.github.com/lalibi/3762289efc5805f8cfcf

    .NOTES
    Original idea from https://gist.github.com/Nora-Ballard/11240204
    #>

    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Object[]] $InputObject,

        [Parameter(Position = 1)]
        [ValidateSet(
            'FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE',
            'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED',
            'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL'
        )]
        [string] $State = 'SHOW',
        [switch] $SuppressErrors = $false,
        [switch] $SetForegroundWindow = $false,
        [int] $ThresholdHours = 24
    )

    Begin {
        $WindowStates = @{
            'FORCEMINIMIZE'      = 11
            'HIDE'               = 0
            'MAXIMIZE'           = 3
            'MINIMIZE'           = 6
            'RESTORE'            = 9
            'SHOW'               = 5
            'SHOWDEFAULT'        = 10
            'SHOWMAXIMIZED'      = 3
            'SHOWMINIMIZED'      = 2
            'SHOWMINNOACTIVE'    = 7
            'SHOWNA'             = 8
            'SHOWNOACTIVATE'     = 4
            'SHOWNORMAL'         = 1
        }

        $Win32ShowWindowAsync = Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SetForegroundWindow(IntPtr hWnd);
'@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

        $handlesFilePath = "$env:APPDATA\WindowHandles.json"

        $global:MainWindowHandles = @{}

        if (Test-Path $handlesFilePath) {
            $json = Get-Content $handlesFilePath -Raw
            $data = $json | ConvertFrom-Json
            $currentTime = Get-Date

            foreach ($key in $data.PSObject.Properties.Name) {
                $handleData = $data.$key

                if ($handleData -and $handleData.Timestamp) {
                    try {
                        $timestamp = [datetime] $handleData.Timestamp
                        if ($currentTime - $timestamp -lt (New-TimeSpan -Hours $ThresholdHours)) {
                            $global:MainWindowHandles[[int] $key] = $handleData
                        }
                    } catch {
                        Write-Verbose "Skipping invalid timestamp for handle $key"
                    }
                } else {
                    Write-Verbose "Skipping entry for handle $key due to missing data"
                }
            }
        }
    }

    Process {
        foreach ($process in $InputObject) {
            $handle = $process.MainWindowHandle

            if ($handle -eq 0 -and $global:MainWindowHandles.ContainsKey($process.Id)) {
                $handle = [int] $global:MainWindowHandles[$process.Id].Handle
            }

            if ($handle -eq 0) {
                if (-not $SuppressErrors) {
                    #Write-Error "Main Window handle is '0'"
                } else {
                    Write-Verbose ("Skipping '{0}' with id '{1}', because Main Window handle is '0'" -f $process.ProcessName, $process.Id)
                }

                continue
            }

            Write-Verbose ("Processing '{0}' with id '{1}' and handle '{2}'" -f $process.ProcessName, $process.Id, $handle)

            $global:MainWindowHandles[$process.Id] = @{
                Handle = $handle.ToString()
                Timestamp = (Get-Date).ToString("o")
            }

            $Win32ShowWindowAsync::ShowWindowAsync($handle, $WindowStates[$State]) | Out-Null

            if ($SetForegroundWindow) {
                $Win32ShowWindowAsync::SetForegroundWindow($handle) | Out-Null
            }

            Write-Verbose ("» Set Window State '{1}' on '{0}'" -f $handle, $State)
        }
    }

    End {
        $data = [ordered] @{}

        foreach ($key in $global:MainWindowHandles.Keys) {
            if ($global:MainWindowHandles[$key].Handle -ne 0) {
                $data["$key"] = $global:MainWindowHandles[$key]
            }
        }

        $json = $data | ConvertTo-Json

        Set-Content -Path $handlesFilePath -Value $json
    }
}

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

#function StartDocker {
$StartDocker = {
    # Check if Docker Desktop is running
    if((docker ps 2>&1) -match '^(?!error)'){
        Write-Host "Docker Desktop is running."
    } else {
        Write-Host "Docker Desktop is not running. Starting Docker Desktop..."
        Start-Process $dockerDesktopPath
        Start-Sleep -Seconds 5
        Get-Process -name "docker desktop" | Set-WindowState -State HIDE

        # Wait for Docker Desktop to start
        $dockerDesktopRunning = $false
        while (!$dockerDesktopRunning) {
            Write-Host "Checking Docker Desktop running"
            if((docker ps 2>&1) -match '^(?!error)'){
                $dockerDesktopRunning = $true
                Write-Host "Docker Desktop is running."
            }
            Start-Sleep -Seconds 1
        }
        Start-Sleep -Seconds 10
    }
}



$selectedIndex = Select-Option -Options $options
#Write-Host "You selected: $($options[$selectedIndex])"
cd C:\devilbox
& $StartDocker


$services = @("up")

#Get-Process -name "WindowsTerminal" | Set-WindowState -State MINIMIZE

if ($($options[$selectedIndex]) -eq 'web') {
    $services += "httpd", "php", "mysql"
} elseif ($($options[$selectedIndex]) -eq 'mysql') {
    $services += "mysql"
}  elseif ($($options[$selectedIndex]) -eq 'web+mailHog') {
    $services += "httpd", "php", "mysql", "mailhog"
} elseif ($($options[$selectedIndex]) -eq 'php+blackFire') {
    $services += "httpd", "php", "mysql", "blackfire"
}


Start-Job  -ScriptBlock { While($true){ (iwr http://alive.loc/).Content; Start-Sleep 60;} }
docker-compose $services
Remove-Job *