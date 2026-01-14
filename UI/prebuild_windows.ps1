# find and copy the files needed for building the UI project.
# called by the build target in UI.csproj.
# these steps are stored as a script for easier reading and editing.

param (
    [string]$OutDir,           # $(ProjectDir)..\bin\$(RuntimeIdentifier)\$(Configuration), like bin\win-x64\Release
    [string]$ProjectDir,
    [string]$RuntimeIdentifier # win-x64, win-arm64, etc.
)

$ErrorActionPreference = "Stop"


# clean paths (PowerShell handles trailing slashes/dots automatically with Get-Item)
$ProjectDir = $ProjectDir.TrimEnd('\')
if ($OutDir -match '^[a-zA-Z]:') {
    $FullOutDir = $OutDir
} else {
    $FullOutDir = Join-Path $ProjectDir $OutDir
}

Write-Host "[PREBUILD] Project Dir: $ProjectDir"
Write-Host "[PREBUILD] Target Dir : $FullOutDir"

# ensure FullOutDir exists and move there
if (!(Test-Path $FullOutDir)) { New-Item -ItemType Directory -Path $FullOutDir | Out-Null }
Set-Location $FullOutDir

# set up Dependencies folder
$DepsFolder = Join-Path $FullOutDir "Dependencies"
if (Test-Path $DepsFolder) { Remove-Item -Recurse -Force $DepsFolder }
New-Item -ItemType Directory -Path $DepsFolder | Out-Null

# 1. copy external dlls managed by NuGet package manager.
# in web CI builds these are installed by 'dotnet restore'.
$Libs = @("libHarfBuzzSharp.dll", "libSkiaSharp.dll")

foreach ($Lib in $Libs) {
    # We MUST look specifically for the native folder matching our RID
    $SpecificPathPart = "runtimes\$RuntimeIdentifier\native"
    $LibSourcePath = (Get-ChildItem -Path "$env:USERPROFILE\.nuget\packages" -Filter $Lib -Recurse | 
                      Where-Object { $_.FullName -like "*$SpecificPathPart*" } | 
                      Select-Object -First 1).FullName

    if ($LibSourcePath -and (Test-Path $LibSourcePath)) {
        Write-Host "[PREBUILD] Copying NuGet dll ($RuntimeIdentifier): $LibSourcePath"
        Copy-Item $LibSourcePath -Destination $DepsFolder
    } else {
        throw "ERROR: Could not find $Lib for $RuntimeIdentifier in NuGet cache '$LibSourcePath' "
    }
}

# 2. copy MesenCore.dll output from building the Core c++ project
$Dll = "MesenCore.dll"
$DllSourcePath = Join-Path $FullOutDir $Dll

if (!(Test-Path $DllSourcePath)) {
    Write-Host "[PREBUILD] $Dll not found in $DllSourcePath . Checking fallback path"
    # Fallback: Check if the file is one level up or if the OutDir had a double-slash issue
    $ParentDir = Split-Path $FullOutDir -Parent
    $DllSourcePath = (Get-ChildItem -Path $ParentDir -Filter $Dll -Recurse | Select-Object -First 1).FullName
}

if ($DllSourcePath -and (Test-Path $DllSourcePath)) {
    Write-Host "[PREBUILD] Copying $Dll from: $DllSourcePath"
    Copy-Item $DllSourcePath -Destination $DepsFolder
} else {
    Write-Host "DEBUG: Contents of $(Split-Path $FullOutDir -Parent):"
    Get-ChildItem -Path (Split-Path $FullOutDir -Parent) -Recurse | Select-Object FullName
    throw "ERROR: Required file $Dll not found in $DllSourcePath"
}

# 3. copy files that exist in source control
Write-Host "[PREBUILD] Copying other dependencies from $ProjectDir\Dependencies"
Copy-Item -Path "$ProjectDir\Dependencies\*" -Destination $DepsFolder -Recurse -Force

# 6. Zip and move back to Project Dir
$ZipPath = Join-Path $FullOutDir "Dependencies.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath }

Write-Host "[PREBUILD] Creating Zip $ZipPath..."
Compress-Archive -Path $DepsFolder -DestinationPath $ZipPath -Force

Move-Item $ZipPath -Destination (Join-Path $ProjectDir "Dependencies.zip") -Force
Write-Host "[PREBUILD] Success."
