# mylatex: スタイル別 LaTeX コンパイル用 Docker イメージ

学会などのスタイル一式を焼き込んだ Docker イメージを，スタイル・版ごとに作成します．
原稿フォルダをマウントしてコンテナを実行すると PDF ができます．
スタイルを焼き込まず，原稿フォルダの `style/` に置いたスタイル一式を使うイメージもあります．

| スタイルフォルダ      | イメージ名                                                    |
| --------------------- | ------------------------------------------------------------- |
| `style/ieicej/3.4a/`  | `ghcr.io/shok1122/mylatex/ieicej:3.4a`（最新版には `:latest` も付与） |
| （なし）              | `ghcr.io/shok1122/mylatex`（原稿フォルダの `style/` を使用．[詳細](#スタイルを埋め込まないイメージ)） |

イメージは main ブランチへの push を契機に GitHub Actions でビルドされ，
GitHub Container Registry (ghcr.io) に公開されます（[イメージの作成](#イメージの作成管理者向け) を参照）．

## 使い方（原稿のコンパイル）

### 準備

```sh
docker pull ghcr.io/shok1122/mylatex/ieicej:3.4a
```

### 基本

原稿のルートフォルダで実行します．フォルダ構成は自由です．

```
root/
├── main.tex
├── section/sect01.tex
├── fig/sample.pdf
└── bib/refs.bib
```

```sh
cd root
docker run --rm -v "$PWD":/work ghcr.io/shok1122/mylatex/ieicej:3.4a main.tex
```

`root/main.pdf` ができます．引数なしで実行するとヘルプを表示します．

```sh
docker run --rm ghcr.io/shok1122/mylatex/ieicej:3.4a
```

### 実行例

```sh
# 大元のファイルを指定 (paper.pdf を出力)
docker run --rm -v "$PWD":/work ghcr.io/shok1122/mylatex/ieicej:3.4a paper.tex

# PDF を dist/ に出力
docker run --rm -v "$PWD":/work ghcr.io/shok1122/mylatex/ieicej:3.4a main.tex -o dist

# サブフォルダにある原稿 (paper/main.pdf を出力)
docker run --rm -v "$PWD":/work ghcr.io/shok1122/mylatex/ieicej:3.4a paper/main.tex

# 保存のたびに自動でコンパイル (Ctrl-C で終了．-it を付ける)
docker run --rm -it -v "$PWD":/work ghcr.io/shok1122/mylatex/ieicej:3.4a -w main.tex

# 中間ファイル (.build/) を削除
docker run --rm -v "$PWD":/work ghcr.io/shok1122/mylatex/ieicej:3.4a --clean

# エンジンを変更
docker run --rm -v "$PWD":/work ghcr.io/shok1122/mylatex/ieicej:3.4a main.tex -e pdflatex

# イメージ内のスタイル一式 (テンプレートを含む) を ./style に取り出す
docker run --rm -v "$PWD":/work ghcr.io/shok1122/mylatex/ieicej:3.4a --export-style

# スタイル名・エンジン・TeX Live の版・同梱ファイルを表示
docker run --rm ghcr.io/shok1122/mylatex/ieicej:3.4a --info
```

毎回入力するのが面倒であれば，シェルに関数を定義しておくと便利です．

```sh
# ~/.bashrc など
ieicej() { docker run --rm -it -v "$PWD":/work ghcr.io/shok1122/mylatex/ieicej:3.4a "$@"; }
# 使用例: ieicej main.tex / ieicej -w main.tex
```

### スタイルを埋め込まないイメージ

`ghcr.io/shok1122/mylatex` にはスタイルが入っていません．代わりに，原稿のルートフォルダの
`style/` に置いたスタイル一式（`.cls`, `.sty`, `.bst` など）を使ってコンパイルします．
イメージにないスタイルや，配布元から入手したばかりの版をそのまま使いたいときに便利です．

```
root/
├── main.tex
├── style/          # スタイル一式 (ieicej.cls, sieicej.bst など)
├── section/sect01.tex
└── bib/refs.bib
```

```sh
docker pull ghcr.io/shok1122/mylatex
cd root
docker run --rm -v "$PWD":/work ghcr.io/shok1122/mylatex main.tex
```

- 原稿での指定方法はスタイルを埋め込んだイメージと同じです（[原稿での指定方法](#原稿での指定方法) を参照）．
  `\documentclass{style/ieicej}` でも `\documentclass{ieicej}` でも読み込め，
  `style/` の下のサブフォルダにあるファイルも名前だけで見つかります．
  大元の `.tex` がサブフォルダにあっても，ルートの `style/` を使います．
- 既定のエンジンは `uplatex` です．`style/mylatex.conf` に `ENGINE=pdflatex` のように書くと変更できます
  （`-e` オプションのほうが優先されます）．
- スタイルを埋め込んだイメージの `--export-style` で取り出した `style/` は，そのまま使えます
  （`mylatex.conf` も一緒に取り出されます）．
- `style/` がなくても，TeX Live に含まれるクラス（`jlreq`, `article` など）の原稿はコンパイルできます．
- オプションは下記と同じです（`--export-style` を除く）．`--info` では `style/` 内のファイルを一覧します．

### オプション

| オプション                 | 説明                                                         |
| -------------------------- | ------------------------------------------------------------ |
| `MAIN.tex`                 | 大元のファイル（拡張子は省略可）．オプションだけを指定して省略した場合は `main.tex` |
| `-e, --engine ENGINE`      | `uplatex`, `platex`, `pdflatex`, `lualatex`, `xelatex`（既定はスタイルごと．ieicej は `uplatex`） |
| `-o, --outdir DIR`         | PDF の出力先（既定: `MAIN.tex` と同じフォルダ）              |
| `-b, --builddir DIR`       | 中間ファイルの置き場所（既定: `MAIN.tex` と同じ階層の `.build`） |
| `-w, --watch`              | ファイルの変更を監視して自動で再コンパイル（`docker run -it` で使用） |
| `-c, --clean`              | 中間ファイルを削除して終了                                   |
| `-v, --verbose`            | TeX の出力をすべて表示                                       |
| `--export-style [DIR]`     | イメージ内のスタイル一式を `DIR`（既定: `style`）にコピー．既存のフォルダには上書きしない（スタイルを埋め込んだイメージのみ） |
| `--info`                   | イメージの情報を表示                                         |
| `-h, --help`               | ヘルプを表示                                                 |
| `-- <latexmkのオプション>` | 以降を latexmk にそのまま渡す                                |

パスはすべて原稿のルートフォルダ（`/work` にマウントしたフォルダ）からの相対パスです．

### 出力について

- PDF は大元の `.tex` と同じフォルダ（`-o` 指定時はそのフォルダ）に出力されます．
- 中間ファイル（`.aux`, `.log`, `.bbl` など）は `.build/` にまとめられ，原稿フォルダは散らかりません．
  2 回目以降は変更があった分だけ再処理されます．
- 生成されるファイルの所有者は，原稿フォルダの所有者と同じになります（root にはなりません）．
- エラー時は，最初のエラー箇所（ファイル名:行番号）を表示し，0 以外の終了コードで終わります．
  ログは `.build/<名前>.log` にあります．

### 原稿での指定方法

イメージ内のスタイルは，版に依存しないフォルダ名 `style/` で参照できます．
パスを付けずにクラス名だけ書いても読み込めます．

```latex
\documentclass[paper]{style/ieicej}   % または \documentclass[paper]{ieicej}
...
\bibliographystyle{style/sieicej}     % または \bibliographystyle{sieicej}
```

`style/ieicej` と書いた場合，LaTeX が
`You have requested document class 'style/ieicej', but the document class provides 'ieicej'.`
という警告を出しますが，動作に影響はありません．

原稿フォルダ内に同名のファイル（例: `style/ieicej.cls`）があれば，そちらが優先されます．
`--export-style` でイメージと同じスタイル一式を原稿の `style/` に取り出しておけば，
Overleaf など Docker 以外の環境でも同じ `\documentclass{style/ieicej}` のままコンパイルできます．

### エンジン設定の上書き

原稿フォルダに `latexmkrc` を置くと，イメージ側の設定より優先されます．

```perl
# latexmkrc の例: pdflatex でコンパイルする
$pdf_mode = 1;
```

優先順位は `-e` オプション > 原稿フォルダの `latexmkrc` > イメージの既定値です
（スタイルを埋め込まないイメージでは，イメージの既定値の代わりに `style/mylatex.conf` の `ENGINE=`，なければ `uplatex`）．

## イメージの作成（管理者向け）

通常は main ブランチに push するだけで，GitHub Actions がイメージをビルド・テストして ghcr.io に公開します．
手元でビルド・確認するときは，このリポジトリの `Makefile` を使います（`make help` で一覧を表示）．

```
.
├── .github/workflows/build.yml   # 自動ビルド・公開 (GitHub Actions)
├── Makefile            # イメージのビルド・テスト・push
├── Dockerfile          # 全イメージ共通の Dockerfile (スタイルを埋め込まないイメージも含む)
├── docker/
│   ├── mylatex         # コンテナのエントリポイント（コンパイル用コマンド）
│   └── latexmkrc       # エンジン設定（latexmk のシステム設定）
├── style/<name>/<version>/   # スタイル一式（そのままイメージに入る）
└── examples/<name>/    # make test で使うサンプル原稿
```

| ターゲット   | 説明                                                         |
| ------------ | ------------------------------------------------------------ |
| `make build` | イメージをビルド（各スタイルの最新版には `:latest` も付与）  |
| `make list`  | スタイルの一覧とビルド状況                                   |
| `make test`  | `examples/<name>/main.tex` をコンパイルして動作確認          |
| `make push`  | イメージをレジストリに push（`:latest` を含む）              |
| `make rmi`   | ビルドしたイメージを削除                                     |
| `make build-plain` などの `-plain` 付き | スタイルを埋め込まないイメージ（`<IMAGE_PREFIX>:latest`）だけを対象にする（`build`, `test`, `push`, `rmi`） |

`STYLE` を指定しない `make build` / `test` / `push` / `rmi` は，スタイルを埋め込まないイメージも対象にします．
`make test-plain` は，`examples/<name>/` の写しに `style/<name>/<version>/` を `style/` としてコピーしてコンパイルします．

| 変数                | 既定値                   | 説明                                                     |
| ------------------- | ------------------------ | -------------------------------------------------------- |
| `STYLE`             | （すべて）               | `ieicej/3.4a` の形式．`ieicej` だけなら全版．省略時はスタイルを埋め込まないイメージも含む |
| `IMAGE_PREFIX`      | `mylatex`                | イメージ名の接頭辞．レジストリを含めてもよい（例: `ghcr.io/<user>/mylatex`） |
| `TEXLIVE_IMAGE`     | `texlive/texlive:latest` | ベースの TeX Live イメージ                               |
| `DOCKER_BUILD_OPTS` | （なし）                 | `docker build` への追加オプション（例: `--pull`）        |
| `SOURCE_URL`        | （なし）                 | イメージに記録するリポジトリの URL．ghcr.io のパッケージがリポジトリと紐付く |

```sh
make build                                      # すべてのイメージをビルド
make build-plain                                # スタイルを埋め込まないイメージだけをビルド
make test STYLE=ieicej/3.4a                     # ビルドしてサンプルで動作確認
make push IMAGE_PREFIX=ghcr.io/<user>/mylatex   # レジストリ名付きでビルドして push
```

`push` は事前に `docker login` しておいてください．イメージ内のヘルプに表示される
イメージ名は `IMAGE_PREFIX` から作られるため，push 先のレジストリ名を付けてビルドしてください．

ベースは TeX Live 公式のフル構成イメージ `texlive/texlive:latest`（現在は TeX Live 2026）です．
TeX Live の版を固定したい場合は `TEXLIVE_IMAGE=texlive/texlive:TL2025-historic` のように指定します．
ベースは展開後に約 9 GB あるため，Docker のイメージ保存先に十分な空きが必要です
（containerd のイメージストアを使っている場合は，保存先は `/var/lib/containerd` です）．

### GitHub Actions による自動ビルド

`.github/workflows/build.yml` が次のように動きます．

| きっかけ                                   | 処理                                                |
| ------------------------------------------ | --------------------------------------------------- |
| main ブランチへの push                     | `make test`（ビルド＋サンプルで確認）→ `make push`   |
| プルリクエスト                             | `make test` のみ（push しない）                      |
| Actions 画面の「Run workflow」（手動実行） | main で実行した場合は push まで，それ以外は test のみ |

- 対象は `Dockerfile`, `Makefile`, `docker/`, `style/`, `examples/` などイメージに関わるファイルが
  変わったときだけです（README の変更などでは動きません）．
- 公開先は `ghcr.io/<リポジトリのオーナー>/mylatex/<name>:<version>` と，スタイルを埋め込まない
  `ghcr.io/<リポジトリのオーナー>/mylatex:latest` で，すべてをビルドし直して push します．
- ghcr.io へのログインには Actions が自動で発行する `GITHUB_TOKEN` を使うため，トークンの登録は不要です．
- 初回の公開後，パッケージは非公開（private）になります．ログインなしで pull できるようにするには，
  GitHub のプロフィール → Packages → `mylatex/ieicej`（スタイルを埋め込まないイメージは `mylatex`）
  → Package settings → Change visibility で Public にしてください
  （スタイルを追加して新しいパッケージができたときも同様です）．
- 先に手元から `make push` で同名のパッケージを作っていた場合，Actions からの push は拒否されます．
  そのパッケージの Package settings → Manage Actions access でこのリポジトリを追加し，Role を Write にしてください．

### スタイルの追加

1. `style/<name>/<version>/` にスタイル一式（`.cls`, `.sty`, `.bst` など）を置く
   - `<name>` はイメージ名になるため英小文字で付けてください
2. 既定のエンジンが `uplatex` 以外の場合は，同じフォルダに `mylatex.conf` を置く
   ```
   ENGINE=pdflatex
   ```
3. `make build STYLE=<name>/<version>` を実行 → `mylatex/<name>:<version>` ができる
4. サンプル原稿を `examples/<name>/main.tex` に置けば `make test` で確認できる
5. main ブランチに push すると，GitHub Actions が `ghcr.io/<オーナー>/mylatex/<name>:<version>` を公開する

### 仕組み

- **スタイルの配置**: スタイル一式を `$TEXMFLOCAL/tex/latex/style/` に，`.bst` を
  `$TEXMFLOCAL/bibtex/bst/style/` にコピーして `mktexlsr` しています．kpathsea は
  `style/ieicej.cls` のようなパス付きの名前を「`style/` で終わるフォルダにある `ieicej.cls`」として探すため，
  パス付き・パス無しの両方で読み込めます．元の一式は `/opt/mylatex/style/` にもあります．
- **スタイルを埋め込まないイメージ**: Dockerfile の `plain` ステージ（`--target plain`）です．
  コンパイル時に `TEXINPUTS`, `BSTINPUTS`, `BIBINPUTS` の先頭に，作業フォルダ（`.`）と
  `/work/style//`（サブフォルダを含む）を加えて名前だけでの指定を可能にしています．
  さらに `/work/style` へのリンク `/tmp/mylatex/style` を置いた `/tmp/mylatex` も加え，
  サブフォルダの原稿からも `style/ieicej` で読み込めるようにしています．
- **共通レイヤ**: Dockerfile の前半（`common` ステージ．エントリポイントなど）はスタイルに依存しないため，
  複数のスタイルのイメージとスタイルを埋め込まないイメージでベースの TeX Live を共有します．
  スタイルごとの増分は数 MB です．
- **エンジンの選択**: `docker/latexmkrc` が環境変数 `MYLATEX_ENGINE`（イメージごとの既定値，`-e` で上書き）
  に応じて latexmk を設定します．
- **ファイルの所有者**: root で起動された場合，マウントしたフォルダの所有者 UID/GID に切り替えて
  コンパイルします（`docker run --user` を指定した場合はそのユーザーのまま）．
