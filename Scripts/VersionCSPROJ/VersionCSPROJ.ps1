<#
    Given -buildNumber and -csprojPath on the command line:
    - Takes the SemVer format version in the csproj <Version> property and breaks out into Major, Minor, and Patch version
    - Re-formats the AssemblyVersion and FileVersion as Major.Minor.BuildNumber.NumericPatch
    - Exports the following into the environment:
      - $env:semVer (e.g. "1.2.3-alpha")
      - $env:majorVersion (e.g. "1" if semVer is "1.2.3-alpha")
      - $env:minorVersion (e.g. "2" if semVer is "1.2.3-alpha")
      - $env:patchVersion (e.g. "3-alpha" if semVer is "1.2.3-alpha")
      - $env:patchVersionNumeric (e.g. "3" if semVer is "1.2.3-alpha")
    - Saves AssemblyVersion, FileVersion, and InformationalVersion
    - Replaces the numeric part of the patch version with the build number
#>

Param
(
    [Parameter(Mandatory)][int]$buildNumber,
    [Parameter(Mandatory)][string]$csprojPath,
    [string]$commit
)

"Build number: $buildNumber"

# Left-padded 0's for build number to allow for better sorting
$paddedBuildNumber = $buildNumber.ToString().PadLeft(5,'0')

$csprojFile = Get-Item $csprojPath

if (!($csprojFile.Exists))
{
    Throw "csproj file """ + $csprojFile.FullName + """ does not exist."
}

$csprojFileFullName = $csprojFile.FullName

"csproj = $csprojFileFullName"

$xml = [xml](get-content $csprojPath)

$propertyGroup = $xml.Project.PropertyGroup | Where {$_.Version}
$version = $propertyGroup.Version

if(!$propertyGroup.Version)
{
    Throw "'Version' property must exist in $csprojFileFullName"
}

$versionParts = $version.Split("{.}")

[int]$majorVersion = $versionParts[0]
[int]$minorVersion = $versionParts[1]
[string]$patchVersion = $versionParts[2]
$patchVersionSplit = $patchVersion.Split("{-}")
[int]$patchVersionNumeric = $patchVersionSplit[0]
[string]$prerelease = $patchVersionSplit[1]

if($prerelease)
{
    $prerelease = "-$prerelease"
}

[string]$modifiedSemVer = "$majorVersion.$minorVersion.$buildNumber$prerelease"

"Major version: $majorVersion"
"Minor version: $minorVersion"
"Patch version: $patchVersion"
"Patch version (numeric part, will be replaced by build number): $patchVersionNumeric"
"Prerelease (if any): $prerelease"

$assemblyVersion = "${majorVersion}.${minorVersion}.${buildNumber}.${patchVersionNumeric}"

"New assembly/file version: $assemblyVersion"

#$assemblyVersionNode = $propertyGroup.AssemblyVersion
#$fileVersionNode = $propertyGroup.FileVersion
#$informationalVersionNode = $propertyGroup.InformationalVersion

if($propertyGroup.AssemblyVersion)
{
    $propertyGroup.AssemblyVersion = $assemblyVersion
}
else
{
    "AssemblyVersion property not present.  Creating..."
    $element = $xml.CreateElement("AssemblyVersion")
    $element.InnerText = $assemblyVersion
    $propertyGroup.AppendChild($element)
}

if($propertyGroup.FileVersion)
{
    $propertyGroup.FileVersion = $assemblyVersion
}
else
{
    "FileVersion property not present.  Creating..."
    $element = $xml.CreateElement("FileVersion")
    $element.InnerText = $assemblyVersion
    $propertyGroup.AppendChild($element)
}

if($commit)
{
    $informationalVersion = "Version $version (Build: $buildNumber, Commit: $commit)"
}
else
{
    $informationalVersion = "Version $version (Build: $buildNumber)"
}

if($propertyGroup.InformationalVersion)
{
    $propertyGroup.InformationalVersion = $informationalVersion
}
else
{
    "InformationalVersion property not present.  Creating..."
    $element = $xml.CreateElement("InformationalVersion")
    $element.InnerText = $informationalVersion
    $propertyGroup.AppendChild($element)
}

# Clear environment variables first
$env:semVer = ""
$env:majorVersion = ""
$env:minorVersion = ""
$env:patchVersion = ""
$env:patchVersionNumeric = ""
$env:paddedBuildNumber = ""

$env:semVer = $version
$env:majorVersion = $majorVersion
$env:minorVersion = $minorVersion
$env:patchVersion = $patchVersion
$env:patchVersionNumeric = $patchVersionNumeric
$env:paddedBuildNumber = $paddedBuildNumber

$propertyGroup.Version = $modifiedSemVer

$xml.Save($csprojFile.FullName)
