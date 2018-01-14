<#
  Rename the AppVeyor build to include a padded build number and the SemVer version
  Requires $env:paddedBuildNumber, usually provided by VersionCSPROJ.ps1
#>
Update-AppveyorBuild -Version "Build-$env:paddedBuildNumber-(v$env:semVer)"
