@echo off
::choco install gh --yes
::gh auth login
::for %%I in (.) do set DirName=%%~nxI
setlocal enabledelayedexpansion
for /d %%D in (*) do (
	set dirName=%%D
	for /F "delims=" %%a in ("!dirName:~0,1!") do (
        if not "%%a"=="_" (
            rem echo !dirName!
            set dirName2=!dirName: =-!
            rem echo !dirName2!
            cd !dirName!

			gh repo create !dirName2! --private
			git init
			git add .
			git commit -m "Initial commit"
			git branch -M main
			git remote add origin https://github.com/LucasGIRARD/!dirName2!.git
			git push -u origin main

            cd ..
        	pause
        )
    )
)
endlocal
pause