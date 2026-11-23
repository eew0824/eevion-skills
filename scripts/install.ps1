$ErrorActionPreference = 'Stop'

$sourceDir = Join-Path $PSScriptRoot '..\skills'
$installDir = Join-Path $env:USERPROFILE '.agents\skills'
$skills = @(Get-ChildItem -LiteralPath $sourceDir -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf
})

if ($skills.Count -eq 0) {
    throw "在 $sourceDir 下找不到含 SKILL.md 的技能目录。请从完整的仓库运行此脚本。"
}

function Get-LinkState($linkPath, $sourcePath) {
    try {
        $item = Get-Item -LiteralPath $linkPath -Force -ErrorAction Stop
    } catch [System.Management.Automation.ItemNotFoundException] {
        return '待创建'
    }
    if ($item.LinkType -eq 'Junction' -and $item.Target -contains $sourcePath) {
        return '已连接'
    }
    return '冲突'
}

Write-Host "安装预览（Junction）"
$created = 0
$alreadyLinked = 0
$conflicts = 0
$failed = 0

$pending = @(foreach ($skill in $skills) {
    $linkPath = Join-Path $installDir $skill.Name
    try {
        $state = Get-LinkState $linkPath $skill.FullName
    } catch {
        $state = '检查失败'
        Write-Host $_.Exception.Message
    }
    Write-Host "[$state] $($skill.Name)"
    Write-Host "  源目录    $($skill.FullName)"
    Write-Host "  安装位置  $linkPath"
    switch ($state) {
        '待创建'   { $skill }
        '已连接'   { $alreadyLinked++ }
        '冲突'     { $conflicts++ }
        '检查失败' { $failed++ }
    }
})

if ($pending.Count -gt 0) {
    Write-Host -NoNewline "现在创建这 $($pending.Count) 个 Junction？[y/N] "
    $answer = [Console]::ReadLine()
    if ($answer -ne 'y') {
        Write-Host '已取消安装。'
        exit 0
    }
    [void][System.IO.Directory]::CreateDirectory($installDir)
}

foreach ($skill in $pending) {
    $linkPath = Join-Path $installDir $skill.Name
    try {
        $state = Get-LinkState $linkPath $skill.FullName
        if ($state -eq '已连接') {
            $alreadyLinked++
            continue
        }
        if ($state -eq '冲突') {
            Write-Host "[冲突] $linkPath 已被占用。"
            $conflicts++
            continue
        }
        if (-not (Test-Path -LiteralPath (Join-Path $skill.FullName 'SKILL.md') -PathType Leaf)) {
            throw "预览中的源目录已变更，找不到 SKILL.md。"
        }

        # Let cmd expand the quoted paths once, including spaces, brackets and percent signs.
        $env:EEVION_SKILL_LINK = $linkPath
        $env:EEVION_SKILL_SOURCE = $skill.FullName
        & $env:ComSpec /d /v:off /c 'mklink /J "%EEVION_SKILL_LINK%" "%EEVION_SKILL_SOURCE%"' | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "mklink /J 创建目录链接失败。" }
        Write-Host "[新建] $linkPath -> $($skill.FullName)"
        $created++
    } catch {
        Write-Host "[失败] $linkPath  $($_.Exception.Message)"
        $failed++
    }
}

Write-Host "新建 $created 个，已连接 $alreadyLinked 个，冲突 $conflicts 个，失败 $failed 个。"
if ($conflicts -gt 0 -or $failed -gt 0) { exit 1 }

try {
    Invoke-Item -LiteralPath $installDir -ErrorAction Stop
} catch {
    Write-Warning "请在文件资源管理器中打开技能目录 $installDir"
}
