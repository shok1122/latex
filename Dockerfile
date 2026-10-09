# syntax=docker/dockerfile:1
#
# Two kinds of images, built with make:
#   --target style  style/<STYLE_NAME>/<STYLE_VERSION>/ is baked in, one image
#                   per style (make build STYLE=ieicej/3.4a -> mylatex/ieicej:3.4a)
#   --target plain  no style; style/ of the mounted project is used at run time
#                   (make build-plain -> mylatex:latest)
ARG TEXLIVE_IMAGE=texlive/texlive:latest
FROM ${TEXLIVE_IMAGE} AS common

# ---- Common layers: identical (and therefore shared) for every image ----
ENV LANG=C.UTF-8 \
    LATEXMKRCSYS=/etc/mylatex/latexmkrc
COPY docker/latexmkrc /etc/mylatex/latexmkrc
COPY --chmod=755 docker/mylatex /usr/local/bin/mylatex
WORKDIR /work
ENTRYPOINT ["mylatex"]

# ---- Image without a style ----
FROM common AS plain
ARG ENGINE=uplatex
ARG IMAGE=mylatex
ENV MYLATEX_ENGINE=${ENGINE} \
    MYLATEX_IMAGE=${IMAGE}
LABEL org.opencontainers.image.title="${IMAGE}" \
      org.opencontainers.image.description="LaTeX build environment that uses the style/ directory of the mounted project"

# ---- Style specific layers ----
FROM common AS style
ARG STYLE_NAME
ARG STYLE_VERSION
ARG ENGINE=uplatex
# Full image name, shown in the usage examples of `mylatex --help`.
ARG IMAGE=mylatex/${STYLE_NAME}:${STYLE_VERSION}

COPY style/${STYLE_NAME}/${STYLE_VERSION}/ /opt/mylatex/style/

# Install the style into TEXMFLOCAL under a directory named "style", so that
# both \documentclass{style/<cls>} and \documentclass{<cls>} resolve
# (kpathsea matches "style/<file>" against any directory ending in style/).
RUN set -eu; \
    test -n "${STYLE_NAME}" && test -n "${STYLE_VERSION}"; \
    texmf="$(kpsewhich -var-value TEXMFLOCAL)"; \
    mkdir -p "$texmf/tex/latex/style" "$texmf/bibtex/bst/style" "$texmf/bibtex/bib/style"; \
    cp -r /opt/mylatex/style/. "$texmf/tex/latex/style/"; \
    find /opt/mylatex/style -name '*.bst' -exec cp {} "$texmf/bibtex/bst/style/" \; ; \
    find /opt/mylatex/style -name '*.bib' -exec cp {} "$texmf/bibtex/bib/style/" \; ; \
    mktexlsr "$texmf"

ENV MYLATEX_STYLE=${STYLE_NAME} \
    MYLATEX_STYLE_VERSION=${STYLE_VERSION} \
    MYLATEX_ENGINE=${ENGINE} \
    MYLATEX_IMAGE=${IMAGE}
LABEL org.opencontainers.image.title="${IMAGE}" \
      org.opencontainers.image.description="LaTeX build environment with the ${STYLE_NAME} ${STYLE_VERSION} style"
