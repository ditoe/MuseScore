# Find the latest MSBuild executable using vswhere and execute it with the provided arguments

$ErrorActionPreference = "Stop"

function Resolve-Properties {
    param(
        [Parameter(ValueFromPipeline)][object]$InputObject,
        [string]$name
    )

    process {
        foreach($prop in $InputObject.psobject.Properties){
            if ($prop.Name -eq $name) {
                Write-Output "$name : $prop.Value"
                return $prop.Value
            }
            Resolve-Properties $prop.Value
        }
    }
}

# Enable delayed expansion
Set-StrictMode -Version Latest

$vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
# Find the latest MSBuild executable
$msbuildPath = & $vswhere -version "[16,)" -products Microsoft.VisualStudio.Product.BuildTools -latest -format json | ConvertFrom-Json
$version = & $vswhere -version "[16,)" -products Microsoft.VisualStudio.Product.BuildTools -latest -property installationVersion -format value

$instanceId = & $vswhere -version "[16,)" -products Microsoft.VisualStudio.Product.BuildTools -latest -property instanceId -format value

$mscoreVc = & $vswhere -version "[16,)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -latest -format json | ConvertFrom-Json
$VSinstanceId = & $vswhere -version "[16,)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -latest -property instanceId -format value
$version = & $vswhere -version "[16,)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationVersion -format value

if (-not $msbuildPath) {
    Write-Output "MSBuild executable not found."
    exit 1
}

# Execute MSBuild with the provided arguments
& $msbuildPath @args

# Exit with the same error level as MSBuild
exit $LASTEXITCODE