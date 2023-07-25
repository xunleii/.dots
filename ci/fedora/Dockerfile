FROM docker.io/fedora:39

ENV CHEZMOI_VERSION=v2.35.2
ENV BINDIR=$HOME/.local/bin

RUN dnf update --assumeyes \
    && dnf install --assumeyes \
        ca-certificates curl git ssh sudo

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN curl -fsLS https://raw.githubusercontent.com/twpayne/chezmoi/${CHEZMOI_VERSION}/assets/scripts/install.sh -o /opt/chezmoi \
    && chmod +x /opt/chezmoi
RUN /opt/chezmoi init --apply https://github.com/xunleii/.dots \
    --promptString "What is your GIT name=github-action" \
    --promptString "What is your GIT email=noreply@github.com"
