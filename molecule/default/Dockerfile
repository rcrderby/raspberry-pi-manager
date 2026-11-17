# syntax=docker/dockerfile:1

# Molecule test image: Debian Trixie with systemd, the user rcr, and the
# Raspberry Pi OS files that the roles edit.
FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        dbus \
        keyboard-configuration \
        locales \
        procps \
        python3 \
        sudo \
        systemd \
        systemd-sysv \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash rcr \
    && echo 'rcr ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/010_rcr-nopasswd \
    && chmod 0440 /etc/sudoers.d/010_rcr-nopasswd \
    && mkdir -p /boot/firmware /etc/chromium.d /etc/cloud /etc/lightdm /etc/netplan /usr/share/wayland-sessions \
    && printf '[all]\n' > /boot/firmware/config.txt \
    && printf 'console=tty1 root=/dev/mmcblk0p2 rootwait' > /boot/firmware/cmdline.txt \
    && printf '[Seat:*]\nautologin-user=rcr\nautologin-session=rpd-labwc\n' > /etc/lightdm/lightdm.conf

CMD ["/lib/systemd/systemd"]
