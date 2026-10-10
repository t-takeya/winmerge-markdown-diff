# WinMerge Markdown Format

MarkdownをPrettierで整形し、整形後の本文をWinMergeに表示して比較する展開プラグインです。比較するだけでは元ファイルを変更しません。

## 必要な環境

- Windows版WinMerge（XMLコマンドプラグイン対応版。2.16.58.2で動作確認）
- Node.js 22以上

Prettier 3.9.9は配布ZIPに含まれます。比較時のインターネット接続やnpmの実行は不要です。

## インストール

1. `dist/winmerge-markdown-diff-1.0.0.zip` を展開します。
2. WinMergeを終了します。
3. 展開先のPowerShellで次を実行します。Program Filesへのインストールは管理者権限が必要です。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -WinMergeDirectory "C:\Program Files\WinMerge"
```

ポータブル版では、そのWinMergeフォルダーを指定してください。Node.jsがPATHにない場合は `-NodeExecutable "C:\Program Files\nodejs\node.exe"` を追加します。

インストーラーは `MergePlugins/Plugins.xml` に `MarkdownFormat` を追加し、`Commands/MarkdownFormat` に整形処理とPrettierを配置します。他のプラグイン定義を保持し、既存のXMLは `Plugins.xml.backup-*` にバックアップします。再実行しても登録は重複しません。Node.jsを移動した場合は再インストールしてください。

## 使い方

WinMergeを起動し、比較対象を選択する画面の「展開プラグイン」で **MarkdownFormat / Format Markdown** を選んで比較します。メニューの表記はWinMergeの言語・バージョンによって異なります。プラグインが無効の場合は「プラグイン」メニューで有効にしてください。

コマンドラインからも指定できます。

```powershell
& "C:\Program Files\WinMerge\WinMergeU.exe" /unpacker MarkdownFormat /wl /wr .\examples\left.md .\examples\right.md
```

`left.md` と `right.md` は書式だけが違うため整形後は一致します。`left.md` と `changed.md` では箇条書き・表の内容変更が差分になります。`/wl /wr` は両側を読み取り専用にする指定です。

既定では手動選択です。`.md`, `.markdown`, `.mdown`, `.mkd` に自動適用したい場合はインストール時に `-Automatic` を付け、WinMerge側でも自動展開を選んでください。

## 整形の内容と制約

- 見出し、箇条書き、表、空行、改行コードなどをPrettierのMarkdown規則で統一します。
- 段落内のソフト改行を連結します。Markdownの明示的な改行は保持します。
- コードブロック内のプログラムは整形しません。
- UTF-8（BOM有無）とBOM付きUTF-16 LE/BEに対応します。比較用ファイルはBOM付きUTF-8です。Shift_JISなどは事前にUTF-8へ変換してください。不正な文字コードはエラーにします。
- ファイルごとの `.prettierrc` や外部プラグインは読み込みません。左右に同じ固定設定を適用します。
- HTMLへのレンダリング比較ではありません。Markdownの書式を揃えたテキスト比較です。同じ表示になるすべての記法を同一視するものではありません。
- 元の書式へ戻す再パック機能はありません。整形結果を保存する場合は別名で保存してください。原本保護には `/wl /wr` を利用できます。

## 削除

WinMergeを終了し、`MergePlugins/Plugins.xml` の `<plugin name="MarkdownFormat">` 要素だけを削除し、`Commands/MarkdownFormat` を削除します。インストール後に他のプラグインを追加した場合、古いバックアップXMLで全体を上書きしないでください。

## 開発

```powershell
npm.cmd ci
npm.cmd test
npm.cmd run build
```

`src/format.mjs` が整形処理、`plugin/MarkdownFormat.xml` が登録定義、`scripts/Install.ps1` がインストーラーです。配布ZIPにはPrettierのライセンスも含めます。

動作確認: Windows / Node.js 24.21.0 / WinMerge 2.16.58.2。整形処理の4テストに加え、WinMergeの非対話比較で「未整形では差分あり」「整形後は一致」「本文変更は差分あり」を確認しています。検証用WinMergeへインストール済みなら `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/Test-WinMerge.ps1 -WinMergeDirectory "検証用WinMergeのフォルダー"` で再実行できます。

仕様の参照先: [WinMergeプラグイン](https://manual.winmerge.org/jp/Plugins.html)、[WinMergeコマンドライン](https://manual.winmerge.org/en/Command_line.html)、[Prettierオプション](https://prettier.io/docs/options)。
