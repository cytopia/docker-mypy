FROM python:3.8-slim-buster as builder

RUN set -eux \
	&& apt update \
	&& apt install -y \
		bc \
		gcc

ARG VERSION=latest
RUN set -eux \
	&& if [ "${VERSION}" = "latest" ]; then \
		pip3 install --no-cache-dir --no-compile mypy; \
	else \
		pip3 install --no-cache-dir --no-compile "mypy>=${VERSION},<$(echo "${VERSION}+0.1" | bc)"; \
	fi \
	\
	&& mypy --version | grep -E '^mypy\s[0-9]+' \
	\
	&& pip3 install --no-cache-dir \
		lxml \
	\
	&& find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf \
	&& find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf

RUN set -eux && ls -lap /usr/lib
RUN set -eux && ls -lap /usr/local/lib

FROM alpine:3 as production
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
#LABEL "org.opencontainers.image.created"=""
#LABEL "org.opencontainers.image.version"=""
#LABEL "org.opencontainers.image.revision"=""
LABEL "maintainer"="cytopia <cytopia@everythingcli.org>"
LABEL "org.opencontainers.image.authors"="cytopia <cytopia@everythingcli.org>"
LABEL "org.opencontainers.image.vendor"="cytopia"
LABEL "org.opencontainers.image.licenses"="MIT"
LABEL "org.opencontainers.image.url"="https://github.com/cytopia/docker-mypy"
LABEL "org.opencontainers.image.documentation"="https://github.com/cytopia/docker-mypy"
LABEL "org.opencontainers.image.source"="https://github.com/cytopia/docker-mypy"
LABEL "org.opencontainers.image.ref.name"="mypy ${VERSION}"
LABEL "org.opencontainers.image.title"="mypy ${VERSION}"
LABEL "org.opencontainers.image.description"="mypy ${VERSION}"

RUN set -eux \
	&& apk add --no-cache python3 \
	&& ln -sf /usr/bin/python3 /usr/bin/python \
	&& ln -sf /usr/bin/python3 /usr/local/bin/python \
	&& find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf \
	&& find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf
COPY --from=builder /usr/local/lib/python3.8/site-packages/ /usr/lib/python3.8/site-packages/
COPY --from=builder /usr/local/bin/mypy /usr/bin/mypy
WORKDIR /data
ENTRYPOINT ["mypy"]
