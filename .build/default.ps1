$PSake.use_exit_on_error = $true

$Here = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$SolutionRoot = (Split-Path -parent $Here)

$ProjectName = "Advanced.Algorithms"

$SolutionFile = "$SolutionRoot\$ProjectName.sln"

## This comes from the build server iteration
if(!$BuildNumber) { $BuildNumber = $env:APPVEYOR_BUILD_NUMBER }
if(!$BuildNumber) { $BuildNumber = "0"}

## The build configuration, i.e. Debug/Release
if(!$Configuration) { $Configuration = $env:Configuration }
if(!$Configuration) { $Configuration = "Release" }

if(!$Version) { $Version = $env:APPVEYOR_BUILD_VERSION }
if(!$Version) { $Version = "0.0.$BuildNumber" }

if(!$Branch) { $Branch = $env:APPVEYOR_REPO_BRANCH }
if(!$Branch) { $Branch = "local" }

if($Branch -eq "beta" ) { $Version = "$Version-beta" }

Import-Module "$Here\Common" -DisableNameChecking

$NuGet = Join-Path $SolutionRoot ".nuget\nuget.exe"

$MSBuild = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\msbuild.exe"
$MSBuild -replace ' ', '` '


FormatTaskName (("-"*25) + "[{0}]" + ("-"*25))

Task default -depends  Document

Task Document {

	$TEMP_REPO_DIR =(Split-Path -parent $SolutionRoot) + "\temp-repo-clone"

	If(test-path $TEMP_REPO_DIR)
	{
		Remove-Item $TEMP_REPO_DIR -Force -Recurse
	}
	
	New-Item -ItemType Directory -Force -Path $TEMP_REPO_DIR
	
	git clone https://github.com/justcoding121/advanced-algorithms.git --branch master $TEMP_REPO_DIR

	If(test-path "$TEMP_REPO_DIR\docs")
	{
		Remove-Item "$TEMP_REPO_DIR\docs" -Force -Recurse
	}
	New-Item -ItemType Directory -Force -Path "$TEMP_REPO_DIR\docs"
	cd "$TEMP_REPO_DIR\docs"
	
	Copy-Item -Path "$SolutionRoot\docs\*" -Destination "$TEMP_REPO_DIR\docs" -Recurse -Force
	
	git config --global credential.helper store
	Add-Content "$HOME\.git-credentials" "https://$($env:github_access_token):x-oauth-basic@github.com`n"
	git config --global user.email $env:github_email
	git config --global user.name "justcoding121"
	git add . -A
	git commit -m "Maintanance commit by build server"
	git push origin master
	
	cd $Here	
}


Task Install-MSBuild {
    if(!(Test-Path $MSBuild)) 
    { 
        cinst microsoft-build-tools -y
    }
}

Task Install-BuildTools -depends Install-MSBuild