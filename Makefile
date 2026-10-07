# mylatex: style/<name>/<version>/ ごとの LaTeX コンパイル用 Docker イメージを作成する
# 使い方は `make help` を参照してください．

ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

IMAGE_PREFIX      ?= mylatex
TEXLIVE_IMAGE     ?= texlive/texlive:latest
DOCKER_BUILD_OPTS ?=
STYLE             ?=
# Repository URL recorded as org.opencontainers.image.source; ghcr.io uses it
# to link the package to the GitHub repository.
SOURCE_URL        ?=

# Available styles as <name>/<version>.
STYLES := $(patsubst $(ROOT)/style/%/,%,$(wildcard $(ROOT)/style/*/*/))

# STYLE may be written as ieicej/3.4a, ieicej:3.4a or style/ieicej/3.4a/;
# a name alone selects all of its versions. Unset means every style.
style_arg := $(patsubst style/%,%,$(patsubst %/,%,$(subst :,/,$(STYLE))))
SELECTED  := $(if $(style_arg),$(filter $(style_arg) $(style_arg)/%,$(STYLES)),$(STYLES))

style_name    = $(firstword $(subst /, ,$(1)))
style_version = $(lastword $(subst /, ,$(1)))
style_image   = $(IMAGE_PREFIX)/$(subst /,:,$(1))
# Default engine of a style: "ENGINE=..." in style/<name>/<version>/mylatex.conf.
style_engine  = $(or $(shell sed -n 's/^ENGINE=[[:space:]]*//p' $(ROOT)/style/$(1)/mylatex.conf 2>/dev/null | tail -n 1),uplatex)

define HELP
使い方: make <ターゲット> [変数=値 ...]

ターゲット
  build   イメージをビルド (各スタイルの最新版には :latest も付与)
  list    スタイルの一覧とビルド状況
  test    examples/<name>/main.tex をコンパイルして動作確認
  push    イメージをレジストリに push (:latest を含む)
  rmi     ビルドしたイメージを削除

変数
  STYLE              対象のスタイル: <name>/<version> (例: ieicej/3.4a) または <name> (全版)．
                     省略時はすべてのスタイル
  IMAGE_PREFIX       イメージ名の接頭辞 (既定: mylatex)．レジストリを含めてもよい
                     (例: ghcr.io/<user>/mylatex)
  TEXLIVE_IMAGE      ベースの TeX Live イメージ (既定: texlive/texlive:latest)
  DOCKER_BUILD_OPTS  docker build への追加オプション (例: --pull)
  SOURCE_URL         イメージに記録するリポジトリの URL (ghcr.io でリポジトリと紐付く)
                     (例: https://github.com/<user>/<repo>)

例
  make build
  make test STYLE=ieicej/3.4a
  make push IMAGE_PREFIX=ghcr.io/<user>/mylatex
endef
export HELP

.DEFAULT_GOAL := help
BUILD_TARGETS := $(addprefix build/,$(STYLES))
.PHONY: help build list test push rmi $(BUILD_TARGETS)

help:
	@printf '%s\n\n' "$$HELP"
	@echo "スタイル: $(or $(STYLES),(なし))"

build: $(addprefix build/,$(SELECTED))
	$(if $(SELECTED),,$(error STYLE=$(STYLE) に該当するスタイルがありません: $(STYLES)))

$(BUILD_TARGETS): build/%:
	@echo "==> $(call style_image,$*) (engine: $(call style_engine,$*), base: $(TEXLIVE_IMAGE))"
	docker build $(DOCKER_BUILD_OPTS) \
	  --build-arg TEXLIVE_IMAGE=$(TEXLIVE_IMAGE) \
	  --build-arg STYLE_NAME=$(call style_name,$*) \
	  --build-arg STYLE_VERSION=$(call style_version,$*) \
	  --build-arg ENGINE=$(call style_engine,$*) \
	  --build-arg IMAGE=$(call style_image,$*) \
	  $(if $(SOURCE_URL),--label org.opencontainers.image.source=$(SOURCE_URL)) \
	  -t $(call style_image,$*) $(ROOT)
	@newest=$$(printf '%s\n' $(filter $(call style_name,$*)/%,$(STYLES)) | sort -V | tail -n 1); \
	if [ "$$newest" = "$*" ]; then \
	  docker tag $(call style_image,$*) $(IMAGE_PREFIX)/$(call style_name,$*):latest; \
	  echo "==> tagged $(IMAGE_PREFIX)/$(call style_name,$*):latest"; \
	fi

list:
	@printf '%-20s %-10s %-30s %s\n' STYLE ENGINE IMAGE STATUS
	@$(foreach s,$(STYLES),img=$(call style_image,$(s)); \
	  st=$$(docker image inspect $$img >/dev/null 2>&1 && echo built || echo -); \
	  printf '%-20s %-10s %-30s %s\n' $(s) $(call style_engine,$(s)) $$img $$st;)

test: build
	@for s in $(SELECTED); do \
	  name=$${s%%/*}; ex=$(ROOT)/examples/$$name; \
	  if [ ! -f $$ex/main.tex ]; then echo "skip: $$s ($$ex/main.tex がありません)"; continue; fi; \
	  echo "==> test $$s ($$ex)"; \
	  tmp=$$(mktemp -d); cp -r $$ex/. $$tmp/; \
	  docker run --rm -v $$tmp:/work $(IMAGE_PREFIX)/$$name:$${s#*/} main.tex && test -s $$tmp/main.pdf \
	    || { echo "test 失敗: $$s (作業フォルダ: $$tmp)" >&2; exit 1; }; \
	  rm -rf $$tmp; echo "ok: $$s"; \
	done

# Push each selected version, and :latest when it points to that version.
push: build
	@for s in $(SELECTED); do \
	  img=$(IMAGE_PREFIX)/$${s%%/*}:$${s#*/}; latest=$(IMAGE_PREFIX)/$${s%%/*}:latest; \
	  docker push $$img || exit 1; \
	  if [ "$$(docker image inspect -f '{{.Id}}' $$latest 2>/dev/null)" = "$$(docker image inspect -f '{{.Id}}' $$img)" ]; then \
	    docker push $$latest || exit 1; \
	  fi; \
	done

rmi:
	@for s in $(SELECTED); do \
	  img=$(IMAGE_PREFIX)/$${s%%/*}:$${s#*/}; latest=$(IMAGE_PREFIX)/$${s%%/*}:latest; \
	  id=$$(docker image inspect -f '{{.Id}}' $$img 2>/dev/null) || continue; \
	  if [ "$$(docker image inspect -f '{{.Id}}' $$latest 2>/dev/null)" = "$$id" ]; then docker rmi $$latest; fi; \
	  docker rmi $$img; \
	done
