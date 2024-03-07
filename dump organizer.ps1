cls
$numberMatchingWords = 10
cd C:\Users\girar\Desktop\source\BDD\Dump20240306
Do {
    $tokens = New-Object System.Collections.Generic.List[object]
    Get-ChildItem -File | ForEach-Object {
        $nameSubA = $_.Name -replace ".sql" -split "_" | Select-Object -First $numberMatchingWords
        $nameSub = $nameSubA -join "_"
        $tokens.Add($nameSub)
    }
    $tokens =  $tokens | Group-Object -NoElement
    $tokens | ForEach-Object {
        if ($_.Count -gt 1) {
            $newFolder = $_.Name
            if (-not (Test-Path $newFolder)) {
                New-Item -ItemType Directory -Path $newFolder | Out-Null
            }

            $filesToMove = Get-ChildItem -File | Where-Object { $_.Name -match $newFolder+"*" }
            $filesToMove | ForEach-Object {
                Move-Item -Path $_.Name -Destination $newFolder
            }            
        }
    }

    echo "$numberMatchingWords matching words"
    $numberMatchingWords--
} While (($numberMatchingWords -gt 0) -and !(!(Get-ChildItem -File))) 
echo "files are organized !!!"