$ErrorActionPreference = 'Stop'

function Wait-ForOrchestrationCompletion($StatusQueryUri) {
    do {
        Start-Sleep -Seconds 5
        $status = irm $StatusQueryUri
    } while ($status.runtimeStatus -eq 'Running')
    
    $status
}

$endpoint = 'http://localhost:7071/api/MyOrchestration_HttpStart'

$r1 = irm "$($endpoint)?delay=70"
Write-Verbose "Started orchestration 1: $($r1.statusQueryGetUri)" -Verbose

Start-Sleep -Seconds 30

$r2 = irm "$($endpoint)?delay=50"
Write-Verbose "Started orchestration 2: $($r2.statusQueryGetUri)" -Verbose

Start-Sleep -Seconds 25

Write-Verbose "You should see timeout exceptions and worker restart messages in the host logs soon..." -Verbose

Write-Verbose "Waiting for orchestration 1 to fail" -Verbose
$s1 = Wait-ForOrchestrationCompletion $r1.statusQueryGetUri
$s1
if ($s1.runtimeStatus -eq 'Failed') {
    Write-Verbose "Orchestration 1 failed (expected because of a genuine timeout): $($s1.output)" -Verbose
} else {
    Write-Warning "Orchestration 1 status (not expected): $($s1.runtimeStatus)"
}

Write-Verbose "Waiting for orchestration 2 to succeed" -Verbose
$s2 = Wait-ForOrchestrationCompletion $r2.statusQueryGetUri
$s2
if ($s2.runtimeStatus -eq 'Completed') {
    Write-Verbose "Orchestration 2 completed (expected because the activity invocation was within the timeout): $($s2.output)" -Verbose
    Write-Warning 'Congratulations! The bug is fixed!'
} else {
    Write-Error "Orchestration 2 status (not expected): $($s2.runtimeStatus)"
}
