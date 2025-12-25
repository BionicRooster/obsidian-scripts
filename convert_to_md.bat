@echo off
setlocal enabledelayedexpansion

set "TARGET_DIR=D:\Obsidian\Main"

echo Converting .prn and .txt files to .md in %TARGET_DIR%
echo.

set /a count=0

for %%F in ("%TARGET_DIR%\*.prn" "%TARGET_DIR%\*.txt") do (
    if exist "%%F" (
        set "basename=%%~nF"
        set "newname=!basename!.md"
        set "newpath=%TARGET_DIR%\!newname!"

        if exist "!newpath!" (
            REM Handle collision - find a unique name
            set /a suffix=1
            :findunique
            set "newname=!basename!_!suffix!.md"
            set "newpath=%TARGET_DIR%\!newname!"
            if exist "!newpath!" (
                set /a suffix+=1
                goto :findunique
            )
        )

        echo Renaming: %%~nxF  -^>  !newname!
        ren "%%F" "!newname!"
        set /a count+=1
    )
)

echo.
exit Done. Converted !count! file(s).

