@{
    # ID used to uniquely identify this module
    GUID = 'd625bfc7-f852-408c-b254-1e5475804539'

    # Author of this module
    Author = 'Jeremiah Haywood'

    # Copyright statement for this module
    Copyright = '(c) 2024 Jeremiah Haywood. All rights reserved.'

    # Version number of this module.
    ModuleVersion = '1.1'

    # Minimum version of PowerShell this module requires
    PowerShellVersion = '7.4'

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    ScriptsToProcess = @(
        '.\classes\AsyncResult',
        '.\classes\DbHandler'
    )

    # required for working with sqlite
    RequiredAssemblies = $(
        if ($env:OS -ne 'Windows_NT') {
            @(
                ".\src\lib\SQLite\linux\System.Data.SQLite.dll"
            )
        } else {
            @(
                ".\src\lib\SQLite\win\System.Data.SQLite.dll"
            )
        }
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Database','Odbc','Postgres','SQLite')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/port-43/DbHandler/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/port-43/DbHandler'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $true

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
