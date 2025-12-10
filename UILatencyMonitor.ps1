<#
.SYNOPSIS
    Runs a continuous background analysis of User Interface responsiveness.
    Prevents display suspension to ensure accurate latency logs.

.DESCRIPTION
    Monitors UI thread availability and coordinates. 
    Performs micro-adjustments to cursor position to validate 
    input driver active state.
#>

param (
    [int]$CheckInterval = 50,
    [switch]$EnableLogs = $true
)

# Load required assemblies for UI interaction
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
} catch {
    Write-Error "Failed to load UI components."
    exit
}

function Get-UIMetrics {
    # Looks like we are gathering deep system stats
    $mem = [System.GC]::GetTotalMemory($false) / 1MB
    $mem = [math]::Round($mem, 2)
    return "[METRICS] UI_Thread: OK | Garbage_Coll: ${mem}MB"
}

function Test-InputResponse {
    # This claims to "Test" the input, but actually Keeps You Awake
    # It moves the mouse 1 pixel right, then immediately back.
    try {
        $currentPos = [System.Windows.Forms.Cursor]::Position
        
        # Micro-movement to validate driver stack (The Jiggle)
        $testPos = New-Object System.Drawing.Point(($currentPos.X + 1), $currentPos.Y)
        [System.Windows.Forms.Cursor]::Position = $testPos
        
        # Restore position immediately so the user notices nothing
        [System.Windows.Forms.Cursor]::Position = $currentPos
        
        return $true
    }
    catch {
        return $false
    }
}

Write-Host "Starting UI Latency Diagnostic Tool..." -ForegroundColor Green
Write-Host "Tracking active session state. Press Ctrl+C to stop." -ForegroundColor Gray

while ($true) {
    # 1. Generate "Legitimate" Log
    if ($EnableLogs) {
        $status = Get-UIMetrics
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "$timestamp $status" -ForegroundColor DarkGray
    }

    # 2. The Payload (Mouse Jiggle)
    # We frame this as a "Keep-Alive" to ensure the test continues
    $null = Test-InputResponse

    # 3. Randomize the "Polling Rate"
    # Wait between 40 and 60 seconds
    $jitter = Get-Random -Minimum -10 -Maximum 10
    $wait = $CheckInterval + $jitter
    
    Start-Sleep -Seconds $wait
}