:: find and copy the files needed for building

:: called by the PreBuildWindows target in UI.csproj
:: steps stored as a batch file for easier reading and editing

set OUTDIR=%~1
set RUNTIME_IDENTIFIER=%~2
set PROJECT_DIR=%~3

cd /d "%OUTDIR%"

if exist Dependencies rd /s /q Dependencies
md Dependencies

xcopy /s "%PROJECT_DIR%\Dependencies\*" Dependencies

copy libHarfBuzzSharp.dll Dependencies
copy libSkiaSharp.dll Dependencies

if exist "MesenCore.dll" (
    copy /y "MesenCore.dll" Dependencies\ >nul
) else (
    echo ERROR: MesenCore.dll missing from %OUTDIR%. Build Core project first.
    exit /b 1
)

:: expand variable to use the full path with ~f. otherwise powershell has difficulty
set "FULL_OUTDIR=%~f1"
set "ZIP=%FULL_OUTDIR%\Dependencies.zip"
del "%ZIP%"

powershell -Command "Compress-Archive -Path (Get-Item '%FULL_OUTDIR%\Dependencies') -DestinationPath '%ZIP%' -Force"
copy /y "%ZIP%" "%PROJECT_DIR%"

