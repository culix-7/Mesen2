:: find and copy the files needed for building

:: called by the PreBuildWindows target in UI.csproj
:: steps stored as a batch file for easier reading and editing

set "PROJECT_DIR=%~2"

:: Remove ending characters if MSBuild passed one
:strip
if "%PROJECT_DIR:~-1%"=="." (set "PROJECT_DIR=%PROJECT_DIR:~0,-1%" & goto strip)
if "%PROJECT_DIR:~-1%"=="\" (set "PROJECT_DIR=%PROJECT_DIR:~0,-1%" & goto strip)

:: cd first before resolving outdir path
:: so outdir is expanded consistently every time
cd /d "%PROJECT_DIR%"
echo Setting up in '%CD%'
set "FULL_OUTDIR=%~f1"

if not exist "%FULL_OUTDIR%" mkdir "%FULL_OUTDIR%"
cd /d "%FULL_OUTDIR%"
echo Running from %FULL_OUTDIR%

if exist Dependencies rd /s /q Dependencies
md Dependencies

:: Search up one level from UI to find the root, then find MesenCore.dll
pushd ..\..
echo Searching for MesenCore.dll in %CD%...
set "CORE_PATH="
for /f "delims=" %%i in ('dir /s /b MesenCore.dll 2^>nul') do (
    set "CORE_PATH=%%i"
    echo %%i | findstr /i "Release" | findstr /v /i "Dependencies" >nul
    if not errorlevel 1 goto :found_it
)
:found_it
popd

:: Get the directory and strip the trailing slash
for %%i in ("%CORE_PATH%") do set "BIN_SRC_DIR=%%~dpi"
if "%BIN_SRC_DIR:~-1%"=="\" set "BIN_SRC_DIR=%BIN_SRC_DIR:~0,-1%"

echo Source Bin Dir: "%BIN_SRC_DIR%"

echo Found Core at: "%CORE_PATH%"

copy /y "%CORE_PATH%" Dependencies
copy /y "%BIN_SRC_DIR%libHarfBuzzSharp.dll" Dependencies
copy /y "%BIN_SRC_DIR%libSkiaSharp.dll" Dependencies

xcopy /s /y "%PROJECT_DIR%Dependencies\*" Dependencies

set "ZIP=%FULL_OUTDIR%\Dependencies.zip"

if exist "%ZIP%" del /f /q "%ZIP%"
powershell -Command "Compress-Archive -Path (Get-Item '%FULL_OUTDIR%\Dependencies') -DestinationPath '%ZIP%' -Force"
copy /y "%ZIP%" "%PROJECT_DIR%"
