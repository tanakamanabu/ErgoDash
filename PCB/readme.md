# ErgoDash PCB

![ErgoDash PCB](https://github.com/omkbd/picture/blob/master/ergodash_pcb1_rev1_1.png)  

## ソケット（ホットスワップ）対応版

Kailh ソケット対応の作業ディレクトリ（`socket-pcb` ブランチ）:

- `Rev1.2-socket-left/` — **左基板。設計の「正」**。ソケット対応の改変はここで行う
- `Rev1.2-socket-right/` — **右基板。左基板をフリップミラーして生成**したもの（手で直接編集しない）

本家由来の `Rev.1/` `Rev.1.1/` `Rev1.2/` は原則変更しない。詳細な設計方針はリポジトリ直下の `CLAUDE.md` を参照。

### ツールのパス

KiCad 10 同梱のものを使う:

- `kicad-cli` … `C:\Program Files\KiCad\10.0\bin\kicad-cli.exe`
- `python`（pcbnew 用）… `C:\Program Files\KiCad\10.0\bin\python.exe`

### ガーバー出力（推奨：スクリプト）

`PCB/gen_gerbers.ps1` で、各基板の `ergodash.kicad_pcb` からガーバー・ドリル・発注用 zip を
`<基板>/ergodash/` にまとめて再生成する。PowerShell で実行:

```powershell
cd PCB

# 両基板のガーバーを作り直す（各自で基板を編集済みの前提）
.\gen_gerbers.ps1

# 左を編集した後：右をミラー再生成してから両方出力
.\gen_gerbers.ps1 -Mirror

# 片方だけ
.\gen_gerbers.ps1 -Board left
```

発注時は `<基板>/ergodash/ergodash-socket-gerber.zip` をアップロードする。

### ガーバー出力（手動 CLI）

スクリプトを使わない場合は基板ごとに以下。`--board-plot-params` で基板に保存済みの
Plot 設定（出力先 `ergodash/`・レイヤ・Protel 拡張子）をそのまま使うのが要点。

```powershell
$cli = "C:\Program Files\KiCad\10.0\bin\kicad-cli.exe"
$d   = "Rev1.2-socket-left"   # 右なら Rev1.2-socket-right
Remove-Item "$d\ergodash\ergodash-*.g*","$d\ergodash\ergodash-*.drl","$d\ergodash\*.zip" -ErrorAction SilentlyContinue
& $cli pcb export gerbers --board-plot-params -o "$d\ergodash\" "$d\ergodash.kicad_pcb"
& $cli pcb export drill --format excellon --excellon-separate-th -o "$d\ergodash\" "$d\ergodash.kicad_pcb"
```

KiCad GUI なら **File → Plot**（設定は基板に保存済み）→ **Generate Drill Files...**（Excellon / PTH・NPTH 別）でも同じ結果。

### 右基板のミラー再生成

右基板は `mirror_right.py` で左基板をフリップミラー（基板外形の垂直中心軸で `Flip(LEFT_RIGHT)`）して作る。
全要素が B.Cu 側へ移り、ネットは不変（schematic-parity が保たれる）。`gen_gerbers.ps1 -Mirror` が内部でこれを呼ぶが、単体でも:

```powershell
$py = "C:\Program Files\KiCad\10.0\bin\python.exe"
& $py mirror_right.py Rev1.2-socket-right\ergodash.kicad_pcb
```

### 注意点

- **基板を編集したら必ずガーバーを作り直す**（GUI 保存も含む）。古いガーバーのまま発注しないこと。
- **右は左から再生成する**。左を直したら `gen_gerbers.ps1 -Mirror` で右をミラー → 両方出力。右の `.kicad_pcb` を手編集しない。
- **左右の `.kicad_sch` は同一に保つ**（電気設計は左右共通。ミラーはネットを変えない）。
- **KiCad GUI を開いたまま実行しても可**（基板ファイルは読むだけ）。ただし GUI に未保存編集があると古い状態で出力されるので、先に保存する。
- ドリル・Edge_Cuts はヘッダのタイムスタンプで毎回 diff が出るが、形状は不変なので気にしなくてよい。
- **発注前に必ずガーバービューア（KiCad GerbView か発注先のプレビュー）で目視確認**。
- `gen_gerbers.ps1` は日本語コメントを含むため **UTF-8 BOM 付き**で保存すること（Windows PowerShell 5.1 は BOM なしだと文字化けして構文エラーになる）。

## 変更履歴

### [rev.1.1]
・圧電スピーカーを追加（試験的）  
・上記に伴うパーツの配置を調整  
・シルク表記を追加
