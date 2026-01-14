Describe "Mesen Prebuild Logic Verification" {
    BeforeAll {
        # set up sandbox in Temp
        $Sandbox = Join-Path $env:TEMP "Mesen_CI_Sandbox"
        if (Test-Path $Sandbox) { Remove-Item $Sandbox -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -Path $Sandbox -ItemType Directory -Force | Out-Null

        # map T: to this sandbox so Join-Path ..\.. works correctly
        if (Get-PSDrive T -ErrorAction SilentlyContinue) { Remove-PSDrive T }
        New-PSDrive -Name T -PSProvider FileSystem -Root $Sandbox | Out-Null

        $script:OldProfile = $env:USERPROFILE
        $env:USERPROFILE = "T:\Users\testuser"
    }

    AfterAll {
        $env:USERPROFILE = $script:OldProfile
        if (Get-PSDrive T -ErrorAction SilentlyContinue) { Remove-PSDrive T }
    }

    Context "Full Mock Isolation" {
        BeforeEach {
            # mock all actions that might cause changes on disk
            Mock Compress-Archive { }
            Mock Copy-Item { }
            Mock Get-Item { param($Path) return [PSCustomObject]@{ FullName = $Path } }
            Mock Move-Item { }
            Mock New-Item { return [PSCustomObject]@{ FullName = "MockedDir" } }
            Mock Remove-Item { }
            Mock Set-Location { }
            Mock Test-Path { return $true }

            Mock Get-ChildItem {
                param($Path, $Filter)
                # This MUST contain 'runtimes\win-x64\native' or the script's filter fails
                if ($Path -like "*\.nuget\*") {
                    return [PSCustomObject]@{ FullName = "T:\Users\testuser\.nuget\packages\runtimes\win-x64\native\libHarfBuzzSharp.dll" }
                }
                if ($Filter -eq "MesenCore.dll") {
                    return [PSCustomObject]@{ FullName = "T:\Users\testuser\code\mesen\bin\win-x64\Release\MesenCore.dll" }
                }
            }
        }

        It "Should handle Relative OutDir (Local Style)" {
            $params = @{
                ProjectDir = "T:\Users\testuser\code\UI"
                OutDir     = "..\bin\Release"
                RuntimeIdentifier = "win-x64"
            }
            { & "$PSScriptRoot/../prebuild_windows.ps1" @params } | Should -Not -Throw
        }

        It "Should handle Absolute OutDir (CI Style)" {
            $params = @{
                ProjectDir = "T:\Users\testuser\code\UI"
                OutDir     = "T:\Users\testuser\code\bin\Release"
                RuntimeIdentifier = "win-x64"
            }
            { & "$PSScriptRoot/../prebuild_windows.ps1" @params } | Should -Not -Throw
        }

        It "Matches the vcxproj OutDir structure" {
            $Repo = "T:\MesenRepo"
            $ProjectDir = "$Repo\UI"
            # This matches your vcxproj logic: $(SolutionDir)\bin\win-$(PlatformTarget)\$(Configuration)\
            $ActualDllLocation = "$Repo\bin\win-x64\Release\MesenCore.dll"

            # 1. Mock NuGet (The script hits this first!)
            Mock Get-ChildItem {
                param($Path, $Filter)
                if ($Path -like "*\.nuget\*") {
                    return [PSCustomObject]@{ FullName = "T:\Users\testuser\.nuget\packages\runtimes\win-x64\native\$Filter" }
                }
                # 2. Mock MesenCore discovery
                if ($Filter -eq "MesenCore.dll") {
                    return [PSCustomObject]@{ FullName = $ActualDllLocation }
                }
                return $null
            } -Verifiable

            Mock Test-Path { return $true }
            Mock Copy-Item { }
            Mock Compress-Archive { }
            Mock Move-Item { }
            Mock New-Item { [PSCustomObject]@{ FullName = "MockedDir" } }
            Mock Set-Location { }

            $params = @{
                ProjectDir        = $ProjectDir
                OutDir            = "..\bin\win-x64\Release"
                RuntimeIdentifier = "win-x64"
            }

            { & "$PSScriptRoot/../prebuild_windows.ps1" @params } | Should -Not -Throw
        }

        It "Should verify the zip ends up in the ProjectDir" {
            $ProjectDir = "T:\Users\testuser\code\mesen\UI"

            $params = @{
                ProjectDir = $ProjectDir
                OutDir     = "T:\Some\Other\Path"
                RuntimeIdentifier = "win-x64"
            }
            { & "$PSScriptRoot/../prebuild_windows.ps1" @params } | Should -Not -Throw

            $ExpectedDestination = Join-Path $ProjectDir "Dependencies.zip"

            Assert-MockCalled Move-Item -ParameterFilter { 
                $Destination -eq $ExpectedDestination
            }
        }
    }
}
