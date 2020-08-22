# POWERSHELL FUNDAMENTALS

## ENVIRONMENT VARIABLES
Variable Name | Variable Description
------------ | -------------
$_.Exception.Message | Try catch will store the exception here.
$Error | Store of all kind of errors.
$ErrorActionPreference | Set the error action execution preference.
$null | It represents nothing.
$PSVersionTable.PSVersion | Get the actual version of Powershell.
$env:PSModulePath | Get PowerShell modules store paths.

### Examples
```
$ErrorActionPreference = "Stop"
```

## COMMANDS
Command Name | Command Description
------------ | -------------
Get-ChildItem | Return all the files contained inside the path you pass.
Get-Command -Noun Content | Get command information such as type, version and source.
Get-ExecutionPolicy | Get the actual execution policy
Get-Help | Get information about commands.
Get-InstalledModule | Gets a list of modules on the computer that were installed by PowerShellGet.
Get-Member | Gets the members, the properties and methods, of objects.
Get-Module | Gets the modules that have been imported, or that can be imported, into a session.
Get-Variable | Get the value of a variable.
Select-Object | Selects specified properties of an object.
Set-ExecutionPolicy | Set the execution policy.
Set-StrictMode | Enables coding rules to enforce better code practices.
Set-Variable | Set a value to a variable.
Update-Help | Downloads the newest help files for PowerShell modules and installs them on your computer.

### Examples
```
Get-ChildItem -Path '.\bogusFolder'
Get-Command -Name Get-Alias
Get-Command -Verb Get
Get-Command -Module Microsoft.PowerShell.Management
Get-Help about_Preference_Variables
Get-Help Add-Content
Get-Help -Name About*
Get-Member -InputObject $color -Name remove
Get-Module -ListAvailable 
Get-Variable -Name color
Select-Object -InputObject $color -Property *
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
Set-StrictMode -Version Latest
Set-Variable -Name color -Value blue
Update-Help -Verbose -Force -ErrorAction SilentlyContinue
Update-Help -Verbose -Force -ErrorAction SilentlyContinue -ErrorVariable UpdateErrors
```

## DATA STRUCTURES

### Array
```
$colorPicker = @('blue', 'white', 'yellow', 'black')
$colorPicker[1]
$colorPicker = $colorPicker + 'orange'
$colorPicker += 'brown'
$colorPicker += @('pink', 'cyan')
```
### ArrayList
```
$MyArrayList = New-Object -TypeName "System.Collections.ArrayList"
$colorPicker = [System.Collections.ArrayList]@('blue', 'white', 'yellow', 'black')
$colorPicker.Add('gray')
$null = $colorPicker.Add('gray')
$colorPicker.Remove('gray')
```
### Hashtable (or dictionary)
```
$users = @{ abertram = 'Adam Bertram'; raquelcer = 'Raquel Cerillo'; }
$users['abertram']
$users.abertram
$users.Keys
$users.Values
$users.Add('natice', 'Natalice Ice')
$users['phrigo'] = 'Phill Rigo'
$users.ContainsKey('johnnyq')
$users['phrigo'] = 'Phoebe Rigo'
$users.Remove('natice')
```
### Custom Object
```
$myFirstCustomObject = New-Object -TypeName PSCustomObject -Property @{OSBuild = 'x'; OSVersion='y'}
$myFirstCustomObject =  [PSCustomObject]@{OSBuild = 'x'; OSVersion='y'}
$myFirstCustomObject.OSBuild
```

## Operators
Command Name | Command Description
------------ | -------------
-eq | Compares two values and returns True if they are equal
-ne | Compares two values and returns True if they are not equal
-gt | Compares two values and returns True if the first is greater than the second
-ge | Compares two values and returns True if the first is greater than or equal to the second
-lt | Compares two values and returns True if the first is less than the second
-le | Compares two values and returns True if the first is less than or equal to the second
-contains | Returns true if the second value is "in" the second. You can use this to determine wheter a value is inside an array.

## Helpfull code examples
```
Get-Member -InputObject $color
Get-Member -InputObject $color -Name remove
Get-Module -ListAvailable
Select-Object -InputObject $color -Property *
Update-Help -Verbose -Force -ErrorAction SilentlyContinue
```

# POWERSHELL FUNCTIONS

## Function
```
function Get-PowerShellProcess { 
	Get-Process PowerShell 
}
```
### Function execution
```
Get-PowerShellProcess
```

## Function with parameters definition
```
function Install-Software {
	param(
		[Parameter(Mandatory)] [ValidateSet('1','2')] [string]$Version,
		[Parameter(Mandatory)] [string]$ComputerName 
	)
	process{
		Write-Host "I installed software version $Version on $ComputerName"
	}
```
### Function execution
```
Install-Software -Version 1 -ComputerName Luis
```

## Function using ValueFromPipeline definition
```
function Install-Software {
	param( 
		[Parameter(Mandatory)] [ValidateSet('1','2')] [string]$Version,
		[Parameter(Mandatory, ValueFromPipeline)] [string]$ComputerName )
	process { 
		Write-Host "I installed software version $Version on $ComputerName" 
	}
}
```
### Function execution
```
$computers = @("SRV1","SRV2","SRV3")
$computers | Install-Software -Version 2
```

# POWERSHELL MODULES
A script module is any valid PowerShell script saved in a .psm1 extension. 

## Module definition
```
function Show-Calendar {
param(
    [DateTime] $start = [DateTime]::Today,
    [DateTime] $end = $start,
    $firstDayOfWeek,
    [int[]] $highlightDay,
    [string[]] $highlightDate = [DateTime]::Today.ToString()
    )

    #actual code for the function goes here see the end of the topic for the complete code sample
}

Export-ModuleMember -Function Show-Calendar
```
## Module manifest
A script module is any valid PowerShell script saved in a .psd1 extension. 
```
New-ModuleManifest -Path myModuleName.psd1 -ModuleVersion "2.0" -Author "YourNameHere"
```
### Usage
```
Import-Module GenericModule
Show-Calendar
```