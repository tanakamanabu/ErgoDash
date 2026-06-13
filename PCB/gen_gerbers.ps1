<#
.SYNOPSIS
    ソケット版 ErgoDash（左右基板）のガーバー / ドリル / zip を再生成する。

.DESCRIPTION
    各基板の ergodash.kicad_pcb から、基板に保存済みの Plot 設定
    (--board-plot-params) を使ってガーバーを出力し、ドリル (PTH/NPTH 別) と
    発注用 zip をまとめて作り直す。出力先は各基板の ergodash\ ディレクトリ。

    -Mirror を付けると、まず左基板を右基板へコピーして mirror_right.py で
    フリップミラー再生成してから両基板を出力する（左を直したとき用）。

.PARAMETER Board
    対象基板: left / right / both（既定 both）。

.PARAMETER Mirror
    出力前に左→右をミラー再生成する。-Board right または both のときのみ有効。

.EXAMPLE
    # 両基板のガーバーを作り直す（基板は各自で編集済みの前提）
    .\gen_gerbers.ps1

.EXAMPLE
    # 左を編集した後：右をミラー再生成してから両方出力
    .\gen_gerbers.ps1 -Mirror

.EXAMPLE
    # 左だけ出力
    .\gen_gerbers.ps1 -Board left

.NOTES
    KiCad GUI で未保存の編集があると古い状態で出力される。先に保存すること。
    生成自体は GUI を開いたままでも可（.kicad_pcb は読むだけ）。
#>
[CmdletBinding()]
param(
    [ValidateSet('left', 'right', 'both')]
    [string]$Board = 'both',
    [switch]$Mirror
)

$ErrorActionPreference = 'Stop'

# --- KiCad のツールを探す（10.0 想定、無ければ最新の bin を拾う） -------------
function Find-KiCadTool([string]$exe) {
    $fixed = "C:\Program Files\KiCad\10.0\bin\$exe"
    if (Test-Path $fixed) { return $fixed }
    $found = Get-ChildItem "C:\Program Files\KiCad\*\bin\$exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if ($found) { return $found.FullName }
    throw "$exe が見つかりません。KiCad のインストール先を確認してください。"
}

$cli    = Find-KiCadTool 'kicad-cli.exe'
$python = Find-KiCadTool 'python.exe'

$pcbDir = $PSScriptRoot
$left   = Join-Path $pcbDir 'Rev1.2-socket-left'
$right  = Join-Path $pcbDir 'Rev1.2-socket-right'

# --- 右基板を左からミラー再生成 ---------------------------------------------
if ($Mirror) {
    if ($Board -eq 'left') {
        Write-Warning '-Board left では -Mirror は無視されます。'
    }
    else {
        Write-Host '== 左 -> 右 ミラー再生成 ==' -ForegroundColor Cyan
        Copy-Item (Join-Path $left 'ergodash.kicad_pcb') (Join-Path $right 'ergodash.kicad_pcb') -Force
        & $python (Join-Path $pcbDir 'mirror_right.py') (Join-Path $right 'ergodash.kicad_pcb')
        if (-not $?) { throw 'ミラー生成に失敗しました。' }
    }
}

# --- 1 基板分のガーバー/ドリル/zip を生成 ------------------------------------
function Build-Gerbers([string]$dir, [string]$name) {
    $pcb = Join-Path $dir 'ergodash.kicad_pcb'
    $out = Join-Path $dir 'ergodash'
    if (-not (Test-Path $pcb)) { throw "基板ファイルがありません: $pcb" }
    if (-not (Test-Path $out)) { New-Item -ItemType Directory $out | Out-Null }

    Write-Host "== $name : 出力 -> $out ==" -ForegroundColor Cyan

    # 古い出力を削除（不要ファイルの残留を防ぐ）
    Remove-Item "$out\ergodash-*.g*", "$out\ergodash-*.drl", "$out\*.zip" -ErrorAction SilentlyContinue

    # ガーバー（出力先・レイヤ・Protel 拡張子は基板に保存済みの設定を使用）
    & $cli pcb export gerbers --board-plot-params -o "$out\" $pcb | Out-Null
    if (-not $?) { throw "$name のガーバー出力に失敗しました。" }

    # ドリル（PTH / NPTH 別ファイル、Excellon）
    & $cli pcb export drill --format excellon --excellon-separate-th -o "$out\" $pcb | Out-Null
    if (-not $?) { throw "$name のドリル出力に失敗しました。" }

    # zip（発注用）
    $files = Get-ChildItem "$out\ergodash-*.g*", "$out\ergodash-*.drl"
    $zip = Join-Path $out 'ergodash-socket-gerber.zip'
    Compress-Archive -Path $files.FullName -DestinationPath $zip -Force

    Write-Host ("   gerber/drill {0} ファイル -> {1}" -f $files.Count, (Split-Path $zip -Leaf)) -ForegroundColor Green
}

if ($Board -in @('left', 'both'))  { Build-Gerbers $left  'LEFT'  }
if ($Board -in @('right', 'both')) { Build-Gerbers $right 'RIGHT' }

Write-Host '完了。発注前にガーバービューアで目視確認を。' -ForegroundColor Yellow
