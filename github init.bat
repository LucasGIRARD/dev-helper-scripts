::@echo off
::choco install gh --yes
::gh auth login
::for %%I in (.) do set DirName=%%~nxI
setlocal enabledelayedexpansion
for /d %%D in (*) do (
	set dirName=%%D
	for /F "delims=" %%a in ("!dirName:~0,1!") do (
        if not "%%a"=="_" (
            set dirName2=!dirName: =-!
            cd !dirName!

            if EXIST htdocs\ (cd htdocs\ && set "htd=a")
        	if EXIST htdocs1\ (cd htdocs1\ && set "htd=a")


			gh repo create !dirName2! --private
			git init
			git add .
			git commit -m "Initial commit"
			git branch -M main
			git remote add origin https://github.com/LucasGIRARD/!dirName2!.git
			pause
			git push -u origin main

			if "%htd%" == "a" (cd ..\ && set "htd=b")
            cd ..
        	pause
        )
    )
)
endlocal
pause