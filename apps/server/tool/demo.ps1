param(
    [ValidateSet('all', 'login', 'duration', 'approve-as-member', 'cancel-other', 'no-token', 'race')]
    [string]$Check = 'all',
    [string]$BaseUrl = ''
)

$ErrorActionPreference = 'Stop'

$envFile = Join-Path $PSScriptRoot '..\..\..\.env'
if (-not (Test-Path $envFile)) {
    Write-Host 'No .env in the repository root. Run: copy .env.example .env' -ForegroundColor Red
    exit 1
}
$settings = @{}
foreach ($line in Get-Content $envFile) {
    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') { $settings[$Matches[1]] = $Matches[2].Trim() }
}
$password = $settings['DEMO_PASSWORD']
if (-not $password) {
    Write-Host 'DEMO_PASSWORD is not set in .env.' -ForegroundColor Red
    exit 1
}
if (-not $BaseUrl) {
    $port = if ($settings['SERVER_PORT']) { $settings['SERVER_PORT'] } else { '8080' }
    $BaseUrl = "http://localhost:$port"
}

function Invoke-Api([string]$Method, [string]$Path, [string]$Token = '', $Body = $null) {
    $curlArgs = @('-s', '-X', $Method, '-w', '\n%{http_code}', '--max-time', '10')
    if ($Token) { $curlArgs += @('-H', "Authorization: Bearer $Token") }
    $bodyFile = $null
    if ($null -ne $Body) {
        $bodyFile = [IO.Path]::GetTempFileName()
        [IO.File]::WriteAllText($bodyFile, ($Body | ConvertTo-Json -Compress))
        $curlArgs += @('-H', 'Content-Type: application/json', '--data-binary', "@$bodyFile")
    }
    try {
        $lines = @(& curl.exe @curlArgs "$BaseUrl$Path")
    } finally {
        if ($bodyFile) { Remove-Item $bodyFile -ErrorAction SilentlyContinue }
    }
    return ConvertTo-ApiResult ($lines -join "`n")
}

function ConvertTo-ApiResult([string]$Output) {
    $cut = $Output.LastIndexOf("`n")
    $status = [int]$Output.Substring($cut + 1).Trim()
    $text = if ($cut -gt 0) { $Output.Substring(0, $cut) } else { '' }
    $json = $null
    try { if ($text) { $json = $text | ConvertFrom-Json } } catch { $json = $null }
    return @{ Status = $status; Body = $text; Json = $json }
}

$script:tokens = @{}

function Get-Token([string]$User) {
    if (-not $script:tokens.ContainsKey($User)) {
        $result = Invoke-Api 'POST' '/api/v1/sessions' -Body @{ username = $User; password = $password; cookie = $false }
        if ($result.Status -ne 201) { throw "Sign-in as $User failed with $($result.Status): $($result.Body)" }
        $script:tokens[$User] = $result.Json.token
    }
    return $script:tokens[$User]
}

function Get-PendingCarcassonne {
    $desk = Invoke-Api 'GET' '/api/v1/desk/loans' (Get-Token 'bibliotekar1')
    $pending = @{}
    foreach ($loan in @($desk.Json)) {
        if ($loan.gameId -eq 'carcassonne' -and $loan.status.kind -eq 'pending') { $pending[$loan.memberId] = $loan.id }
    }
    return $pending
}

$script:passed = 0
$script:failed = 0

function Hide-Token([string]$Text) { return $Text -replace '"token":"([^"]{12})[^"]*"', '"token":"$1..."' }

function Show-Result([string]$Request, [string]$Expected, $Result, [bool]$Ok) {
    Write-Host "  $Request"
    Write-Host "  expected: $Expected"
    Write-Host "  status:   $($Result.Status)"
    Write-Host "  body:     $(Hide-Token $Result.Body)"
    if ($Ok) {
        Write-Host '  result:   OK' -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host '  result:   UNEXPECTED' -ForegroundColor Red
        $script:failed++
    }
    Write-Host ''
}

function Show-Title([string]$Name, [string]$Text) { Write-Host "== [$Name] $Text ==" -ForegroundColor Cyan }

function Skip-Check([string]$Reason) {
    Write-Host "  skipped: $Reason" -ForegroundColor Yellow
    Write-Host '  reset the database: docker compose down -v; docker compose up -d --build' -ForegroundColor Yellow
    Write-Host ''
    $script:failed++
}

function Test-Login {
    Show-Title 'login' 'clan1 signs in as an app (cookie: false), so the token comes in the body'
    $result = Invoke-Api 'POST' '/api/v1/sessions' -Body @{ username = 'clan1'; password = $password; cookie = $false }
    if ($result.Status -eq 201) { $script:tokens['clan1'] = $result.Json.token }
    $ok = $result.Status -eq 201 -and $result.Json.user.role -eq 'member' -and $result.Json.token
    Show-Result 'POST /api/v1/sessions {username: clan1, cookie: false}' '201, user.role member, token' $result $ok
}

function Test-Duration {
    Show-Title 'duration' 'clan1 asks for a loan of 8 days'
    $result = Invoke-Api 'POST' '/api/v1/loans' (Get-Token 'clan1') @{ gameId = 'catan'; durationDays = 8 }
    $ok = $result.Status -eq 422 -and $result.Json.code -eq 'invalid-loan-duration' -and $result.Json.max -eq 7
    Show-Result 'POST /api/v1/loans {gameId: catan, durationDays: 8}' '422 invalid-loan-duration, max 7' $result $ok
}

function Test-ApproveAsMember {
    Show-Title 'approve-as-member' 'clan1 tries to approve its own pending loan'
    $id = (Get-PendingCarcassonne)['clan1']
    if (-not $id) { Skip-Check 'clan1 has no pending Carcassonne loan'; return }
    $result = Invoke-Api 'POST' "/api/v1/desk/loans/$id/approval" (Get-Token 'clan1')
    $ok = $result.Status -eq 403 -and $result.Json.code -eq 'not-allowed'
    Show-Result "POST /api/v1/desk/loans/$id/approval  (token: clan1)" '403 not-allowed' $result $ok
}

function Test-CancelOther {
    Show-Title 'cancel-other' "clan1 tries to cancel clan2's loan"
    $id = (Get-PendingCarcassonne)['clan2']
    if (-not $id) { Skip-Check 'clan2 has no pending Carcassonne loan'; return }
    $result = Invoke-Api 'POST' "/api/v1/loans/$id/cancellation" (Get-Token 'clan1')
    $ok = $result.Status -eq 404 -and $result.Json.code -eq 'not-found'
    Show-Result "POST /api/v1/loans/$id/cancellation  (token: clan1)" '404 not-found, same as a loan that does not exist' $result $ok
}

function Test-NoToken {
    Show-Title 'no-token' 'a call without a token'
    $result = Invoke-Api 'GET' '/api/v1/me/loans'
    $ok = $result.Status -eq 401 -and $result.Json.code -eq 'sign-in-required'
    Show-Result 'GET /api/v1/me/loans  (no Authorization header)' '401 sign-in-required' $result $ok
}

function Test-Race {
    Show-Title 'race' 'two approvals at the same moment for the only free Carcassonne copy'
    $pending = Get-PendingCarcassonne
    if (-not ($pending['clan1'] -and $pending['clan2'])) { Skip-Check 'Carcassonne needs pending loans of clan1 and clan2'; return }
    $token = Get-Token 'bibliotekar1'
    $startAt = (Get-Date).AddSeconds(3)
    $send = {
        param([string]$Url, [string]$Token, [datetime]$StartAt)
        while ((Get-Date) -lt $StartAt) { Start-Sleep -Milliseconds 5 }
        $lines = @(& curl.exe -s -X POST -w '\n%{http_code}' --max-time 10 -H "Authorization: Bearer $Token" $Url)
        $lines -join "`n"
    }
    $jobs = foreach ($member in 'clan1', 'clan2') {
        $url = "$BaseUrl/api/v1/desk/loans/$($pending[$member])/approval"
        Start-Job -Name $member -ScriptBlock $send -ArgumentList $url, $token, $startAt
    }
    $null = Wait-Job $jobs
    $results = @{}
    foreach ($job in $jobs) {
        $results[$job.Name] = ConvertTo-ApiResult ((Receive-Job $job) -join "`n")
        Remove-Job $job
    }
    $statuses = @($results['clan1'].Status, $results['clan2'].Status) | Sort-Object
    $loser = @($results.Values | Where-Object { $_.Status -eq 409 })
    $ok = ($statuses -join ',') -eq '200,409' -and $loser.Count -eq 1 -and $loser[0].Json.code -eq 'no-free-copy'
    foreach ($member in 'clan1', 'clan2') {
        $last = $member -eq 'clan2'
        $request = "POST /api/v1/desk/loans/$($pending[$member])/approval  ($member's request, token: bibliotekar1)"
        if ($last) {
            Show-Result $request 'one 200, the other 409 no-free-copy' $results[$member] $ok
        } else {
            Write-Host "  $request"
            Write-Host "  status:   $($results[$member].Status)"
            Write-Host "  body:     $($results[$member].Body)"
            Write-Host ''
        }
    }
}

$health = Invoke-Api 'GET' '/health'
if ($health.Status -ne 200) {
    Write-Host "The server at $BaseUrl does not answer /health (status $($health.Status)). Run: docker compose up -d --build" -ForegroundColor Red
    exit 1
}
Write-Host "Server: $BaseUrl" -ForegroundColor Cyan
Write-Host ''

$checks = [ordered]@{
    'login'             = { Test-Login }
    'duration'          = { Test-Duration }
    'approve-as-member' = { Test-ApproveAsMember }
    'cancel-other'      = { Test-CancelOther }
    'no-token'          = { Test-NoToken }
    'race'              = { Test-Race }
}
foreach ($name in $checks.Keys) {
    if ($Check -eq 'all' -or $Check -eq $name) { & $checks[$name] }
}

$color = if ($script:failed -eq 0) { 'Green' } else { 'Red' }
Write-Host "$($script:passed) as expected, $($script:failed) not" -ForegroundColor $color
if ($script:failed -gt 0) { exit 1 }
