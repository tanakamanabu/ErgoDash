# CLAUDE.md

## プロジェクト概要

このリポジトリは [omkbd/ErgoDash](https://github.com/omkbd/ErgoDash) のフォークです。
**目的: 既存の ErgoDash を改変して、キースイッチのソケット（ホットスワップ）対応版を作ること。**

ErgoDash は左右分離型の自作キーボードで、本リポジトリにはハードウェア設計データ一式が含まれます。ソフトウェアプロジェクトではなく、ビルド・テスト・サーバー起動といった概念はありません。

## リポジトリ構成

- `PCB/` — KiCad の基板設計データ（本プロジェクトの主な改変対象）
  - `Rev.1/`, `Rev.1.1/`, `Rev1.2/` — 各リビジョン。`Rev1.2` が最新
  - 各リビジョンに `.sch`（回路図）、`.kicad_pcb`（基板レイアウト）、`gerber/`（製造データ）、`library/`（部品ライブラリ）を含む
- `Case/` — ケースの図面データ（.ai / .eps / .svg / .pdf）
- `Firmware/` — VIA 対応ファームウェアの zip（QMK 本体は [qmk_firmware の ergodash ディレクトリ](https://github.com/qmk/qmk_firmware/tree/master/keyboards/ergodash) を参照）
- `Doc/` — ビルドガイド（日英）、ショップリスト
- `mini/` — 派生モデル ErgoDash mini のデータ一式（同様の構成）

## Git 運用

- `origin` = tanakamanabu/ErgoDash（このフォーク）、`upstream` = omkbd/ErgoDash（本家）
- ソケット対応の作業は `socket-pcb` ブランチで行う。`master` は本家追従用
- 本家由来の既存リビジョン（Rev.1 / Rev.1.1 / Rev1.2）のデータは原則変更せず、ソケット対応版は新しいリビジョンとして追加する

## 設計データに関する注意

- KiCad ファイルは KiCad 5.0 で作成されている（`kicad_pcb (version 20171130)`）。新しい KiCad で開くとフォーマットが変換されるため、使用バージョンと変換の有無を意識すること
- ソケット対応では Kailh ソケット用のフットプリント追加・基板裏面のパターン変更が中心になる。元設計は MX 互換・Alps 両対応のスルーホール実装である点に注意
- 基板レイアウトを変更したら gerber データも再生成して同じリビジョンのディレクトリに含めること
- ドキュメントは日本語が一次情報（`Doc/build.md`）、英語版（`Doc/build-en.md`）は追従
