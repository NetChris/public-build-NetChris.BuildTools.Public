<#
    Sample runner for VersionCSPROJ.ps1
    After running this, check Sample.csproj to see that:
        AssemblyVersion property is added
        FileVersion property is added
        InformationalVersion property is added
#>
.\VersionCSPROJ.ps1 -buildNumber 123 -csprojPath .\Sample.csproj -commit x1234567