# Make starship beautiful prompt
Invoke-Expression (&starship init powershell)

# Import Terminal Icons
Import-Module -Name Terminal-Icons

# AutoCompletion Options navigation like bash
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineOption -HistorySearchCursorMovesToEnd
Set-PSReadlineKeyHandler -Key Ctrl+n -Function HistorySearchForward
Set-PSReadlineKeyHandler -Key Ctrl+p -Function HistorySearchBackward

# Suggestions like fish shell
Set-PSReadLineOption -PredictionSource History
Set-PSReadlineOption -HistoryNoDuplicates
Set-PSReadLineOption -PredictionViewStyle ListView

# Aliases
function cd... { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }
function kcon { Get-Process conhost | Where-Object { $_.CPU -ge 0 } | Stop-Process -Force }
function knode { Get-Process node | Stop-Process -Force }

# AutoCompletion for z module
Register-ArgumentCompleter -CommandName z -ScriptBlock {
	param($commandName, $parameterName, $wordToComplete) 
	  Search-NavigationHistory $commandName -List | %{ $_.Path} | ForEach-Object {
	  New-Object -Type System.Management.Automation.CompletionResult -ArgumentList $_,
		  $_,
		  "ParameterValue",
		  $_
  }
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
