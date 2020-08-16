# POWERSHELL FUNDAMENTALS

## ENVIRONMENT VARIABLES

Variable Name | Variable Description
------------ | -------------
$null | It represents nothing.
$_.Exception.Message | Try catch will store the exception here.
$Error | Store of all kind of errors.
$PSVersionTable.PSVersion | Get the actual version of Powershell.
$ErrorActionPreference | Set the error action execution preference.

## COMMANDS

Command Name | Command Description
------------ | -------------
Get-Help | Get information about commands.
Get-Member | Gets the members, the properties and methods, of objects.
Get-InstalledModule | Gets a list of modules on the computer that were installed by PowerShellGet.
Get-Module | Gets the modules that have been imported, or that can be imported, into a session.
Select-Object | Selects specified properties of an object.
Set-StrictMode | Enables coding rules to enforce better code practices.
Update-Help | Downloads the newest help files for PowerShell modules and installs them on your computer.
Set-ExecutionPolicy | Set the execution policy.
Get-ChildItem | Return all the files contained inside the path you pass.


### Examples
```
Get-Help about_Preference_Variables
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