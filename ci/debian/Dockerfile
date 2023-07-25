FROM docker.io/debian:bookworm-slim

ENV CHEZMOI_VERSION=v2.35.2
ENV BINDIR=$HOME/.local/bin

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates curl git locales ssh sudo \
    && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN curl -fsLS https://raw.githubusercontent.com/twpayne/chezmoi/${CHEZMOI_VERSION}/assets/scripts/install.sh -o /opt/chezmoi \
    && chmod +x /opt/chezmoi
RUN /opt/chezmoi init --apply https://github.com/xunleii/.dots \
    --promptString "What is your GIT name=github-action" \
    --promptString "What is your GIT email=noreply@github.com"
