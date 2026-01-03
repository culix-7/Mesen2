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

cd Dependencies
del ..\Dependencies.zip

powershell -Command "Compress-Archive -Path * -DestinationPath '..\Dependencies.zip' -Force"
copy /y "..\Dependencies.zip" "%PROJECT_DIR%"
