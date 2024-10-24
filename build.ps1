Task 'Build' SQLiteLibs, {}

Task 'SQLiteLibs' {
    if (Test-Path ./src) {
        Remove-Item -Path ./src -Force -Recurse -ErrorAction Stop | Out-Null
    }

    if (Test-Path ./temp) {
        Remove-Item -Path ./temp -Force -Recurse -ErrorAction Stop | Out-Null
    }

    $SQLiteVersion  = "1.0.119"
    $BaseLibDir     = "./src/lib/SQLite"
    $WinLibDir      = "$BaseLibDir/win"
    $LinuxLibDir    = "$BaseLibDir/linux"
    $TempLibDir     = "./temp/Stub.System.Data.SQLite.Core.NetStandard.$SQLiteVersion.0"
    $LibDirectories = @(
        $BaseLibDir,
        $WinLibDir,
        $LinuxLibDir
    )
    $RemoveDirectories = @(
        "./temp"
    )

    # Create lib directories
    foreach ($Directory in $LibDirectories) {
        New-Item -Path $Directory -ItemType Directory -Force | Out-Null
    }

    # Install packages
    nuget install Stub.System.Data.SQLite.Core.NetStandard -Version $SQLiteVersion -outputdirectory ./temp | Out-Null

    # Copy dlls to lib path
    Copy-Item -Path "$TempLibDir/lib/netstandard2.1/*.dll" -Destination $WinLibDir -Recurse -Force | Out-Null
    Copy-Item -Path "$TempLibDir/runtimes/win-x64/native/*.dll" -Destination $WinLibDir -Recurse -Force | Out-Null
    Copy-Item -Path "$TempLibDir/lib/netstandard2.1/*.dll" -Destination $LinuxLibDir -Recurse -Force | Out-Null
    Copy-Item -Path "$TempLibDir/runtimes/linux-x64/native/*.dll" -Destination $LinuxLibDir -Recurse -Force | Out-Null

    # Cleanup directories
    foreach ($Directory in $RemoveDirectories) {
        Remove-Item -path $Directory -Force -Recurse | Out-Null
    }
}
