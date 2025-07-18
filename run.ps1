$ErrorActionPreference = 'Stop'

$endpoint = 'http://localhost:7071/api/MyOrchestration_HttpStart'

$r1 = irm "$($endpoint)?delay=70"
Write-Verbose "Started orchestration 1: $($r1.Id)" -Verbose

Start-Sleep -Seconds 30

$r2 = irm "$($endpoint)?delay=50"
Write-Verbose "Started orchestration 2: $($r2.Id)" -Verbose

Start-Sleep -Seconds 25

Write-Verbose "You should see timeout exceptions in the host logs soon..." -Verbose

Start-Sleep -Seconds 30

Write-Verbose "Checking orchestration 1 status ($($r1.statusQueryGetUri))" -Verbose
$s1 = irm $r1.statusQueryGetUri
$s1
if ($s1.runtimeStatus -eq 'Failed') {
    Write-Verbose "Orchestration 1 failed (expected because of a genuine timeout): $($s1.output)" -Verbose
} else {
    Write-Warning "Orchestration 1 status (not expected): $($s1.runtimeStatus)"
}

Start-Sleep -Seconds 60

Write-Verbose "Checking orchestration 2 status ($($r2.statusQueryGetUri))" -Verbose
$s2 = irm $r2.statusQueryGetUri
$s2
if ($s2.runtimeStatus -eq 'Completed') {
    Write-Verbose "Orchestration 2 completed (expected because the activity invocation was within the timeout): $($s2.output)" -Verbose
} else {
    Write-Warning "Orchestration 2 status (not expected): $($s2.runtimeStatus)"
}
