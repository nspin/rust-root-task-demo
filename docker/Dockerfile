#
# Copyright 2023, Colias Group, LLC
#
# SPDX-License-Identifier: BSD-2-Clause
#

FROM debian:bookworm

RUN apt-get update -q && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    # for seL4
    python3-dev \
    python3-venv \
    cmake \
    ninja-build \
    device-tree-compiler \
    libxml2-utils \
    qemu-utils \
    qemu-system-x86 \
    ipxe-qemu \
    # for bindgen
    libclang-dev \
    # for test script
    python3-pexpect \
    # for hacking
    bash-completion \
    man \
    sudo \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

ARG RUSTUP_CHANNEL

RUN curl -sSf https://sh.rustup.rs | \
        bash -s -- -y --no-modify-path \
            --default-toolchain $RUSTUP_CHANNEL \
            --component rust-src

ENV PATH=/root/.cargo/bin:$PATH

ENV SEL4_INSTALL_DIR=/opt/seL4

RUN git clone --branch 14.0.0 https://github.com/seL4/seL4.git

RUN set -eux; \
    cd seL4; \
    python3 -m venv pyenv; \
    export PATH=$(realpath ./pyenv/bin):$PATH; \
    pip install tools/python-deps; \
    cmake \
        -DCMAKE_INSTALL_PREFIX=$SEL4_INSTALL_DIR \
        -DKernelSel4Arch=x86_64 \
        -DKernelPlatform=pc99 \
        -DKernelFSGSBase=msr \
        -DKernelSupportPCID=OFF \
        -DKernelIOMMU=OFF \
        -DKernelFPU=FXSAVE \
        -DKernelVerificationBuild=OFF \
        -G Ninja \
        -S . \
        -B build; \
    ninja -C build all; \
    ninja -C build install; \
    rm -rf $(pwd);

ARG UID
ARG GID

RUN set -eux; \
    if [ $UID -eq 0 ]; then \
        if [ $GID -ne 0 ]; then \
            echo "error: \$UID == 0 but \$GID != 0" >&2; \
            exit 1; \
        fi; \
    else \
        if getent passwd $UID; then \
            echo "error: \$UID $UID already exists" >&2; \
            exit 1; \
        fi; \
        if ! getent group $GID; then \
            groupadd --gid $GID x; \
        fi; \
        useradd --uid $UID --gid $GID --groups sudo --create-home x; \
    fi;

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $UID

RUN set -eux; \
    if [ $UID -ne 0 ]; then \
        curl -sSf https://sh.rustup.rs | \
            bash -s -- -y --no-modify-path --default-toolchain none; \
    fi;

ENV PATH=/home/x/.cargo/bin:$PATH

ENV SHELL=/bin/bash

WORKDIR /work
