function Start-AllCoverage{
    param(
        [Parameter()] [string]$CoverageFolderName = "Coverage",
        [Parameter()] [string]$ProjectsPath = ""
    )
    begin{
        Show-VerboseImportantMessage -Message "Starting Test Coverage Report of Tests projects"
    }
    process{
        $InitialExecutionPath = Get-Location
        
        if($ProjectsPath -ne ""){
            if(Test-Path -Path $ProjectsPath){
                Set-Location $ProjectsPath
            }
        }
        
        $ValidTestProjects = Get-AllTestProjectNames | Select-ValidProjectsByDependecies

        if($ValidTestProjects.Length -gt 0){

            @("Valid dependencies", "Coverlet version: 1.0.3* or above | SDK version: 16.2* or above | Target framework: 3.*") | Show-VerboseMessage
        
            $ValidTestProjects | Start-Coverage -CoverageFolderName $CoverageFolderName
        }
        else{
            $ActualLocation = Get-Location

            "0 Tests projects found in the actual path: $ActualLocation" | Show-VerboseMessage
        }
        
        Set-Location -Path $InitialExecutionPath
    }
    end{
        Show-VerboseImportantMessage -Message "Finishing Test Coverage Report of Tests projects"
    }
}

function Start-Coverage{
    param(
        [Parameter(Mandatory, ValueFromPipeline)] [string]$ProjectName,
        [Parameter()] [string]$CoverageFolderName = "Coverage",
        [Parameter()] [string]$SourceCodePath = ""
    )
    begin{
        Set-StrictMode -Version Latest
        Install-ReportGenerator
    }
    process{
        $InitialProjectExecutionPath = Get-Location
        
        Show-VerboseImportantMessage -Message "Starting Test Coverage Report of $ProjectName project"
        
        if($SourceCodePath -ne ""){
            if(Test-Path -Path $SourceCodePath){
                Set-Location $SourceCodePath
            }
        }
        
        if((Read-IsValidProject -ProjectName $ProjectName) -eq $false){
            $ProjectTargetFramework = Get-ProjectTargetFramework -ProjectName $ProjectName
            $CoverletVersion = Search-ProjectPackageReference -ProjectName $ProjectName -PackageReferenceIncludeValue "coverlet.collector"
            $SDKVersion = Search-ProjectPackageReference -ProjectName $ProjectName -PackageReferenceIncludeValue "Microsoft.NET.Test.Sdk"
            
            @(
                "Test Coverage Report of $ProjectName project stopped.",
                "Valid dependencies:Coverlet version: 1.3.0 or above | SDK version: 16.2* or above | Target framework: 3.*",
                "Project name: $ProjectName | Coverlet: $CoverletVersion | SDK: $SDKVersion | Target framework: $ProjectTargetFramework | Can be cover?: No"
            ) | Show-VerboseMessage

            Show-VerboseImportantMessage -Message "Finishing Test Coverage Report of $ProjectName project" -PrintLine $true

            return 
        }

        "1. Creating cobertura and report folders." | Show-VerboseMessage
        
        Set-StrictMode -Off
        if($TimeStamp -eq $null){
            $TimeStamp = Get-Date -Format o | ForEach-Object { $_ -replace ":", "." }
        }
        Set-StrictMode -Version Latest

        $CoberturaFolder = Join-Path -Path "C:\$CoverageFolderName\$TimeStamp\Cobertura" -ChildPath $ProjectName | New-Folder
        $ReportFolder = Join-Path -Path "C:\$CoverageFolderName\$TimeStamp\Report" -ChildPath $ProjectName | New-Folder
            
        if(((Test-Path -Path $CoberturaFolder) -and (Test-Path -Path $ReportFolder)) -eq $false){
            "Creation of cobertura and report folders failed." | Show-VerboseMessage
            
            Show-VerboseImportantMessage -Message "Finishing Test Coverage Report of $ProjectName project" -PrintLine

            return 
        }
        
        @("Cobertura and report folders created successfully.", "2. Executing 'dotnet test ...' command.") | Show-VerboseMessage

        Invoke-DotNetTestCommand -ProjectName $ProjectName -Collect "XPlat Code Coverage" -CoberturaFolder $CoberturaFolder -CoberturaFormat "cobertura"
            
        if((Read-IsValidCoberturaPath -CoberturaFolder $CoberturaFolder) -eq $false){
            "'dotnet test ...' command failed." | Show-VerboseMessage

            Show-VerboseImportantMessage -Message "Finishing Test Coverage Report of $ProjectName project" -PrintLine

            return 
        }

        @("'dotnet test ...' command executed successfully.", "3. Executing 'reportgenerator ...' command.") | Show-VerboseMessage

        Invoke-ReportGeneratorCommand -CoberturaFolder $CoberturaFolder -ReportFolder $ReportFolder

        if((Test-Path -Path $ReportFolder) -eq $false){

            "3. 'reportgenerator ...' command failed." | Show-VerboseMessage

            Show-VerboseImportantMessage -Message "Finishing Test Coverage Report of $ProjectName project"

            return 
        }

        @("'reportgenerator ...' command executed successfully.", "4. Executing 'start ...' command.") | Show-VerboseMessage
        
        Invoke-ChromeCommand -Path $ReportFolder

        "'start ...' command executed successfully." | Show-VerboseMessage

        Show-VerboseImportantMessage -Message "Finishing Test Coverage Report of $ProjectName project" -PrintLine $true
        
        Set-Location -Path $InitialProjectExecutionPath
        
    }
}

function Select-ValidProjectsByDependecies{
    param(
        [Parameter(Mandatory, ValueFromPipeline)] [string]$ProjectName
    )
    process{
        $CoverletVersion = Search-ProjectPackageReference -ProjectName $ProjectName -PackageReferenceIncludeValue "coverlet.collector"
        $SDKVersion = Search-ProjectPackageReference -ProjectName $ProjectName -PackageReferenceIncludeValue "Microsoft.NET.Test.Sdk"
        $ProjectTargetFramework = Get-ProjectTargetFramework -ProjectName $ProjectName
            
        $IsValidProjectDependencies = Read-IsValidProjectByDependencies -ProjectTargetFramework $ProjectTargetFramework -CoverletVersion $CoverletVersion -SDKVersion $SDKVersion
        $CanBeCover = @({'No'},{'Yes'})[$IsValidProjectDependencies]

        Write-Verbose "------------------------------------------------------------------------------------------------------------" 
        Write-Verbose "Project name: $ProjectName | Coverlet: $CoverletVersion | SDK: $SDKVersion | Target framework: $ProjectTargetFramework | Can be cover?: $CanBeCover" 

        if($IsValidProjectDependencies -eq $true){
            return $ProjectName
        }
    }
}

function Search-ProjectPackageReference{
    param(
        [Parameter(Mandatory)] [string]$ProjectName,
        [Parameter(Mandatory)] [string]$PackageReferenceIncludeValue
    )
    process{
        $InitialPath = Get-Location
        $PackageReferenceValue = "Not found"
        try{
            Set-Location -Path $ProjectName
            $FilePath = "$ProjectName.csproj"

            if(Test-Path -Path $FilePath){
                $XML = [xml](Get-Content -Path $FilePath)
                $Query = "//PackageReference[@Include='$PackageReferenceIncludeValue']"
                $ResultElement = Select-Xml -XPath $query -Path $FilePath | Select-Object -ExpandProperty Node
                if($ResultElement -ne $null){
                    if($ResultElement.Version -ne $null){
                        $PackageReferenceValue = $ResultElement.Version    
                    }
                }
            }
        }
        catch{
            @("An error occurred in $MyInvocation.MyCommand:", "$_.Exception") | Show-VerboseMessage
        }
        finally{
            Set-Location -Path $InitialPath
        }
        return $PackageReferenceValue
    }
}

function Get-AllTestProjectNames{
    process{
        $CoberturaSubfolder = Get-ChildItem -Filter "*Tests*" | Select-Object
        return $CoberturaSubfolder
    }
}

function Get-CoberturaPath{
    param(
        [Parameter(Mandatory)] [string]$CoberturaFolder
    )
    process{
        $CoberturaSubfolder = Get-ChildItem -Path $CoberturaFolder -Recurse -Directory -Force | Select-Object 
        $CoveragePath = Join-Path -Path $CoberturaFolder -ChildPath $CoberturaSubfolder
        $CoverageFullPath = "$CoveragePath\coverage.cobertura.xml "
        return $CoverageFullPath
    }
}

function Get-ProjectTargetFramework{
    param(
        [Parameter(Mandatory)] [string]$ProjectName
    )
    process{
        $InitialPath = Get-Location
        $TargetFramework = "Not found"

        try{
            Set-Location -Path $ProjectName
            $FilePath = "$ProjectName.csproj"

            if(Test-Path -Path $FilePath){
                $XML = [xml](Get-Content -Path $FilePath)
                $TargetFramework = $XML.Project.PropertyGroup | select TargetFramework
                $TargetFramework = $TargetFramework.TargetFramework
            }
            else{
                $TargetFramework = "Not found"
            }
        }
        catch{
            @("An error occurred in $MyInvocation.MyCommand:", "$_.Exception") | Show-VerboseMessage
        }
        finally{
            Set-Location -Path $InitialPath
        }

        return $TargetFramework
    }
}

function Install-ReportGenerator{
    process{
        try
        {
            @("attempting to install reportgenerator") | Show-VerboseMessage
            if(Get-Command reportgenerator){
                @("reportgenerator installed already.") | Show-VerboseMessage
                return
            }
            dotnet tool install -g dotnet-reportgenerator-globaltool
            dotnet tool install dotnet-reportgenerator-globaltool --tool-path tools
            dotnet new tool-manifest
            dotnet tool install dotnet-reportgenerator-globaltool
            @("reportgenerator installed successfully") | Show-VerboseMessage
        }
        catch{
            @("An error occurred in $MyInvocation.MyCommand:", "$_.Exception") | Show-VerboseMessage
        }
        finally{}
    }
}

function Invoke-DotNetTestCommand{
    param(
        [Parameter(Mandatory)] [string]$ProjectName,
        [Parameter(Mandatory)] [string]$Collect,
        [Parameter(Mandatory)] [string]$CoberturaFolder,
        [Parameter(Mandatory)] [string]$CoberturaFormat
    )
    process{
        
        $InitialPath = Get-Location
        try{
            $ActualErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            
            Set-Location -Path $ProjectName
            
            dotnet test --verbosity:"q" --collect:"$Collect" --results-directory:"$CoberturaFolder" -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format="$CoberturaFormat"
        }
        catch{
            @("An error occurred in $MyInvocation.MyCommand:", "$_.Exception") | Show-VerboseMessage
        }
        finally{
            $ErrorActionPreference = $ActualErrorActionPreference
            Set-Location -Path $InitialPath
        }
    }
}

function Invoke-ReportGeneratorCommand{
    param(
        [Parameter(Mandatory)] [string]$CoberturaFolder,
        [Parameter(Mandatory)] [string]$ReportFolder
    )
    process{

        try{
            $CoberturaSubfolder = Get-ChildItem -Path $CoberturaFolder -Recurse -Directory -Force | Select-Object 
            $CoveragePath = Join-Path -Path $CoberturaFolder -ChildPath $CoberturaSubfolder
            $CoverageFullPath = "$CoveragePath\coverage.cobertura.xml"
            
            reportgenerator -reports:"$CoverageFullPath" -targetdir:"$ReportFolder" -verbosity:"Off"
        }
        catch{
            @("An error occurred in $MyInvocation.MyCommand:", "$_.Exception") | Show-VerboseMessage
        }
        finally{}
    }
}

function Invoke-ChromeCommand{
    param(
        [Parameter(Mandatory)] [string]$Path,
        [string]$FileToOpen = "index.html"
    )
    process{
        $InitialPath = Get-Location

        try{
            Set-Location -Path $Path

            Start-Process -FilePath "$FileToOpen" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        }
        catch{
            @("An error occurred in $MyInvocation.MyCommand:", "$_.Exception") | Show-VerboseMessage
        }
        finally{
            Set-Location -Path $InitialPath
        }
    }
}

function Read-IsValidCoberturaPath{
    param(
        [Parameter(Mandatory)] [string]$CoberturaFolder
    )
    process{
        return Get-CoberturaPath -CoberturaFolder $CoberturaFolder | Test-Path
    }
}

function Read-IsValidProjectByDependencies{
    param(
        [Parameter()] [string]$ProjectTargetFramework,
        [Parameter()] [string]$CoverletVersion,
        [Parameter()] [string]$SDKVersion
    )
    process{
        $IsValidTargetFamework = $ProjectTargetFramework.Contains("3.") -or $ProjectTargetFramework.Contains("2.")
        $IsValidCoverletVersion = $CoverletVersion -eq "1.3.0"
        $IsValidSDKVersion = $SDKVersion.Contains("16.")

        return ($IsValidTargetFamework -eq $true) -and ($IsValidCoverletVersion -eq $true) -and ($IsValidSDKVersion -eq $true)
    }
}

function Read-IsValidProject{
    param(
        [Parameter(Mandatory)] [string]$ProjectName
        
    )
    process{
        $CoverletVersion = Search-ProjectPackageReference -ProjectName $ProjectName -PackageReferenceIncludeValue "coverlet.collector"
        $SDKVersion = Search-ProjectPackageReference -ProjectName $ProjectName -PackageReferenceIncludeValue "Microsoft.NET.Test.Sdk"
        $ProjectTargetFramework = Get-ProjectTargetFramework -ProjectName $ProjectName

        $IsValidProjectDependencies = Read-IsValidProjectByDependencies -ProjectTargetFramework $ProjectTargetFramework -CoverletVersion $CoverletVersion -SDKVersion $SDKVersion

        return $IsValidProjectDependencies
    }
}

function New-Folder{
    param(
        [Parameter(Mandatory, ValueFromPipeline)] [string]$FolderPath
    )
    process{

        try{

            if(Test-Path -Path $FolderPath){
                Remove-Item -Path $FolderPath -Recurse -Force
            }
            return New-Item -Path $FolderPath -ItemType directory
        }
        catch{ 
            @("An error occurred in $MyInvocation.MyCommand:", "$_.Exception") | Show-VerboseMessage
        }
    }
}

function Show-VerboseImportantMessage{
    param(
        [Parameter(Mandatory)] [string]$Message,
        [Parameter()] [boolean]$PrintLine = $false
    )
    process{
        Write-Verbose "/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/"
        Write-Verbose "/*/*/*/*/* $Message */*/*/*/*/*/*/"
        Write-Verbose "/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/"
        Write-Verbose " "
        if($PrintLine -eq $true){
            Write-Verbose "----------------------------------------------------------------------------------"
            Write-Verbose " "
        }
    }
}

function Show-VerboseMessage{
    param(
        [Parameter(Mandatory, ValueFromPipeline)] [string]$Message
    )
    process{
        Write-Verbose "$Message"
        Write-Verbose " "
    }   
}

Export-ModuleMember -Function Start-AllCoverage
Export-ModuleMember -Function Start-Coverage