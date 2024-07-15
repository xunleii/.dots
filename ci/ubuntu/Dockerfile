FROM docker.io/library/ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        fish \
        git \
        gzip \
        keychain \
        locales \
        neovim \
        unzip \
    && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN BINDIR=$HOME/.local/bin \
    sh -c "$(curl -fsLS https://raw.githubusercontent.com/twpayne/chezmoi/master/assets/scripts/install.sh)" \
    -- init --apply https://github.com/xunleii/.dots \
        --promptString "What is your GIT name=github-action" \
        --promptString "What is your GIT email=noreply@github.com"
