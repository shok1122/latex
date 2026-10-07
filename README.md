# mylatex: スタイル別 LaTeX コンパイル用 Docker イメージ

学会などのスタイル一式を焼き込んだ Docker イメージを，スタイル・版ごとに作成します．
原稿フォルダをマウントしてコンテナを実行すると PDF ができます．

| スタイルフォルダ      | イメージ名                                      |
| --------------------- | ----------------------------------------------- |
| `style/ieicej/3.4a/`  | `mylatex/ieicej:3.4a`（最新版には `:latest` も付与） |

以下ではイメージ名を `mylatex/ieicej:3.4a` と書きます．レジストリから取得する場合は，
`ghcr.io/<user>/mylatex/ieicej:3.4a` のようにレジストリを含めた名前に読み替えてください．

## 使い方（原稿のコンパイル）

### 準備

```sh
docker pull mylatex/ieicej:3.4a
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
docker run --rm -v "$PWD":/work mylatex/ieicej:3.4a main.tex
```

`root/main.pdf` ができます．引数なしで実行するとヘルプを表示します．

```sh
docker run --rm mylatex/ieicej:3.4a
```

### 実行例

```sh
# 大元のファイルを指定 (paper.pdf を出力)
docker run --rm -v "$PWD":/work mylatex/ieicej:3.4a paper.tex

# PDF を dist/ に出力
docker run --rm -v "$PWD":/work mylatex/ieicej:3.4a main.tex -o dist

# サブフォルダにある原稿 (paper/main.pdf を出力)
docker run --rm -v "$PWD":/work mylatex/ieicej:3.4a paper/main.tex

# 保存のたびに自動でコンパイル (Ctrl-C で終了．-it を付ける)
docker run --rm -it -v "$PWD":/work mylatex/ieicej:3.4a -w main.tex

# 中間ファイル (.build/) を削除
docker run --rm -v "$PWD":/work mylatex/ieicej:3.4a --clean

# エンジンを変更
docker run --rm -v "$PWD":/work mylatex/ieicej:3.4a main.tex -e pdflatex

# イメージ内のスタイル一式 (テンプレートを含む) を ./style に取り出す
docker run --rm -v "$PWD":/work mylatex/ieicej:3.4a --export-style

# スタイル名・エンジン・TeX Live の版・同梱ファイルを表示
docker run --rm mylatex/ieicej:3.4a --info
```

毎回入力するのが面倒であれば，シェルに関数を定義しておくと便利です．

```sh
# ~/.bashrc など
ieicej() { docker run --rm -it -v "$PWD":/work mylatex/ieicej:3.4a "$@"; }
# 使用例: ieicej main.tex / ieicej -w main.tex
```

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
| `--export-style [DIR]`     | イメージ内のスタイル一式を `DIR`（既定: `style`）にコピー．既存のフォルダには上書きしない |
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

優先順位は `-e` オプション > 原稿フォルダの `latexmkrc` > イメージの既定値です．

## イメージの作成（管理者向け）

イメージの作成・公開は，このリポジトリの `Makefile` で行います（`make help` で一覧を表示）．

```
.
├── Makefile            # イメージのビルド・テスト・push
├── Dockerfile          # 全スタイル共通の Dockerfile
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

| 変数                | 既定値                   | 説明                                                     |
| ------------------- | ------------------------ | -------------------------------------------------------- |
| `STYLE`             | （すべて）               | `ieicej/3.4a` の形式．`ieicej` だけなら全版              |
| `IMAGE_PREFIX`      | `mylatex`                | イメージ名の接頭辞．レジストリを含めてもよい（例: `ghcr.io/<user>/mylatex`） |
| `TEXLIVE_IMAGE`     | `texlive/texlive:latest` | ベースの TeX Live イメージ                               |
| `DOCKER_BUILD_OPTS` | （なし）                 | `docker build` への追加オプション（例: `--pull`）        |

```sh
make build                                      # すべてのスタイルをビルド
make test STYLE=ieicej/3.4a                     # ビルドしてサンプルで動作確認
make push IMAGE_PREFIX=ghcr.io/<user>/mylatex   # レジストリ名付きでビルドして push
```

`push` は事前に `docker login` しておいてください．イメージ内のヘルプに表示される
イメージ名は `IMAGE_PREFIX` から作られるため，push 先のレジストリ名を付けてビルドしてください．

ベースは TeX Live 公式のフル構成イメージ `texlive/texlive:latest`（現在は TeX Live 2026）です．
TeX Live の版を固定したい場合は `TEXLIVE_IMAGE=texlive/texlive:TL2025-historic` のように指定します．
ベースは展開後に約 9 GB あるため，Docker のイメージ保存先に十分な空きが必要です
（containerd のイメージストアを使っている場合は，保存先は `/var/lib/containerd` です）．

### スタイルの追加

1. `style/<name>/<version>/` にスタイル一式（`.cls`, `.sty`, `.bst` など）を置く
   - `<name>` はイメージ名になるため英小文字で付けてください
2. 既定のエンジンが `uplatex` 以外の場合は，同じフォルダに `mylatex.conf` を置く
   ```
   ENGINE=pdflatex
   ```
3. `make build STYLE=<name>/<version>` を実行 → `mylatex/<name>:<version>` ができる
4. サンプル原稿を `examples/<name>/main.tex` に置けば `make test` で確認できる

### 仕組み

- **スタイルの配置**: スタイル一式を `$TEXMFLOCAL/tex/latex/style/` に，`.bst` を
  `$TEXMFLOCAL/bibtex/bst/style/` にコピーして `mktexlsr` しています．kpathsea は
  `style/ieicej.cls` のようなパス付きの名前を「`style/` で終わるフォルダにある `ieicej.cls`」として探すため，
  パス付き・パス無しの両方で読み込めます．元の一式は `/opt/mylatex/style/` にもあります．
- **共通レイヤ**: Dockerfile の前半（エントリポイントなど）はスタイルに依存しないため，
  複数のスタイルのイメージでベースの TeX Live を共有します．スタイルごとの増分は数 MB です．
- **エンジンの選択**: `docker/latexmkrc` が環境変数 `MYLATEX_ENGINE`（イメージごとの既定値，`-e` で上書き）
  に応じて latexmk を設定します．
- **ファイルの所有者**: root で起動された場合，マウントしたフォルダの所有者 UID/GID に切り替えて
  コンパイルします（`docker run --user` を指定した場合はそのユーザーのまま）．
