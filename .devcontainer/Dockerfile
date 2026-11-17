# syntax=docker/dockerfile:1

# Development container image, also used by GitHub CI.
FROM python:3.14-slim-trixie@sha256:9aaa474097d094040649f2162a627c0049b408f52138d980916788d80f04802f

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# libatomic1 is required by the Node.js that pre-commit installs on arm64.
# en_US.UTF-8 is required by the VS Code Git extension, which runs git with LC_ALL=en_US.UTF-8.
# sshpass is required by Ansible for SSH password authentication.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        git \
        less \
        libatomic1 \
        locales \
        openssh-client \
        sshpass \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash vscode

# Root-owned virtual environment with the tools from requirements.txt.
ENV PATH=/opt/venv/bin:${PATH} \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1

COPY requirements.txt /tmp/requirements.txt

# The base image's own pip is removed; the virtual environment has its own.
RUN python -m venv /opt/venv \
    && pip install --require-hashes --no-deps -r /tmp/requirements.txt \
    && pip check \
    && rm /tmp/requirements.txt \
    && /usr/local/bin/python -m pip uninstall --yes pip

# Mount points for the named volumes in devcontainer.json.
RUN install -d -o vscode -g vscode \
        /home/vscode/.cache \
        /home/vscode/.cache/pre-commit \
        /home/vscode/.ssh \
        /workspaces/raspberry-pi-manager/collections \
    && chmod 700 /home/vscode/.ssh

USER 1000:1000

WORKDIR /workspaces/raspberry-pi-manager

CMD ["/bin/bash"]
