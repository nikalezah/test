param([Switch][Alias("up")]$Update, [Alias("u")]$UserName, $Password, $IssueKey)

$begin =      3600 * 9		# время запуска
$end   = 30 + 3600 * 18		# время остановки

if ($Update) {
	Invoke-WebRequest https://raw.githubusercontent.com/nikalezah/test/master/test.ps1 -OutFile $PSCommandPath
} elseif ($UserName -And $Password) {
	New-Object System.Management.Automation.PSCredential $UserName, (ConvertTo-SecureString $Password -AsPlainText -Force) `
		| Export-CliXml -Path "$PSScriptRoot\credential.xml"
} else {
	if (Test-Path "$PSScriptRoot\credential.xml") {
		Set-JiraConfigServer 'https://job-jira.otr.ru/'
		New-JiraSession (Import-CliXml -Path "$PSScriptRoot\credential.xml")
		$now = [System.Math]::Round((Get-Date).TimeOfDay.TotalSeconds)
		if ($IssueKey) {
			$issue = Get-JiraIssue $IssueKey
			if (-not $issue) { break }
			if (-not $issue.IssueType.subtask) {
				Write-Host "   $issue`n   Не является саб-таском!`n" -f Red
				break
			}
			$transition = 4
			$till = $begin
			Write-Host "   В $($begin / 3600):00 будет запущен саб-таск`n   $issue`n"
		} else {
			$transition = 711
			$till = $end
			Write-Host "   В $(($end - 30) / 3600):00 будет найден и остановлен запущенный саб-таск`n"
		}
		Start-Sleep (($now -lt $till) ? $till - $now : 86400 + $till - $now)
	} else {
		Write-Host "need to set credential"
		break
	}
}

while(1) {
	if ($transition -eq 711) {
		$issue = Get-JiraIssue -Query 'assignee = currentUser() AND status = "In Progress" AND issueType = Sub-task'
		if (-not $issue) {
			Write-Host "              $(Get-Date -Format "HH:mm:ss") × Отсутствует запущенный саб-таск!`n" -f Red
			break
		}
	}
	Invoke-JiraIssueTransition $issue.Key $transition
	$now = [System.Math]::Round((Get-Date).TimeOfDay.TotalSeconds)
	if ($transition -eq 711) {
		Write-Host "              $(Get-Date -Format "HH:mm:ss") ■ $issue`n"
		$transition = 4
		Start-Sleep (86400 + $begin - $now)
	} else {
		Write-Host "   $(Get-Date -Format "dd.MM.yyyy HH:mm:ss") ► [$($issue.Key)]"
		$transition = 711
		Start-Sleep ($end - $now)
	}
}

# function Export-Credential ($username, $password) {
# 	New-Object System.Management.Automation.PSCredential $username, (ConvertTo-SecureString $password -AsPlainText -Force) `
# 		| Export-CliXml -Path "$PSScriptRoot\credential.xml"
# }

# function Create-JiraSession {
# 	Set-JiraConfigServer 'https://job-jira.otr.ru/'
# 	New-JiraSession (Import-CliXml -Path "$PSScriptRoot\credential.xml")
# }

# Export-Credential $username $password
# Create-JiraSession

# function Update-Myself {
# 	Invoke-WebRequest https://raw.githubusercontent.com/nikalezah/test/master/test.ps1 -OutFile $PSCommandPath
# }
