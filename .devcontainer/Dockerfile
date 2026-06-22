# syntax=docker/dockerfile:1
FROM ubuntu:22.04

LABEL description="ghostkey Flutter dev environment with Android emulator & VNC preview"
LABEL maintainer="ghostkey"

# ──────────────────────────────────────────────
# Prevent interactive prompts
# ──────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ──────────────────────────────────────────────
# System packages
# ──────────────────────────────────────────────
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        # Build & dev essentials
        git \
        curl \
        wget \
        unzip \
        xz-utils \
        zip \
        sudo \
        ca-certificates \
        software-properties-common \
        gnupg \
        # OpenJDK 17
        openjdk-17-jdk \
        openjdk-17-jre \
        # Android emulator dependencies
        libgl1-mesa-dev \
        libgl1-mesa-glx \
        libegl1-mesa \
        libgles2-mesa \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxss1 \
        libxtst6 \
        libpulse0 \
        libnss3 \
        libnspr4 \
        libcups2 \
        libdrm2 \
        libgbm1 \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libgtk-3-0 \
        # Virtual framebuffer & VNC
        xvfb \
        tigervnc-standalone-server \
        tigervnc-common \
        # Python & websockify
        python3 \
        python3-pip \
        python3-websockify \
        python3-numpy \
        # ADB & tools
        adb \
        # File watching
        inotify-tools \
        entr \
        # Misc
        jq \
        pciutils \
        # Required for flutter linux desktop (optional but helpful)
        clang \
        cmake \
        ninja-build \
        pkg-config \
        libgtk-3-dev \
        liblzma-dev \
        libstdc++-12-dev \
        # Networking
        netcat \
        net-tools \
        # For node.js web server
        nodejs \
        npm \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────
# Node.js 20.x (if the default node is too old)
# ──────────────────────────────────────────────
RUN node_version="$(node --version 2>/dev/null | cut -d. -f1 | tr -d 'v')" && \
    if [ -z "$node_version" ] || [ "$node_version" -lt 20 ]; then \
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
        apt-get install -y nodejs && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# ──────────────────────────────────────────────
# Android SDK
# ──────────────────────────────────────────────
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk

RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" && \
    cd /tmp && \
    CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" && \
    wget -q "${CMDLINE_TOOLS_URL}" -O cmdline-tools.zip && \
    unzip -q cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools/" && \
    mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" && \
    rm -f cmdline-tools.zip && \
    # Set up paths for the license acceptance step
    export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${PATH}" && \
    yes | sdkmanager --sdk_root="${ANDROID_HOME}" --licenses > /dev/null 2>&1 || true && \
    # Install core SDK components
    sdkmanager --sdk_root="${ANDROID_HOME}" \
        "platform-tools" \
        "emulator" \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "system-images;android-34;google_apis_playstore;x86_64" \
        "cmdline-tools;latest" \
        > /dev/null 2>&1 || true && \
    yes | sdkmanager --sdk_root="${ANDROID_HOME}" --licenses > /dev/null 2>&1 || true

# ──────────────────────────────────────────────
# Flutter SDK
# ──────────────────────────────────────────────
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

RUN cd /opt && \
    FLUTTER_VERSION="3.22.3" && \
    wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -O flutter.tar.xz && \
    tar xf flutter.tar.xz && \
    rm -f flutter.tar.xz && \
    chown -R root:root /opt/flutter && \
    # Disable Flutter telemetry & analytics
    /opt/flutter/bin/flutter config --no-analytics 2>/dev/null && \
    /opt/flutter/bin/flutter config --android-sdk "${ANDROID_HOME}" 2>/dev/null && \
    # Pre-cache Dart/Flutter tooling (skipping heavy web/linux artifacts)
    /opt/flutter/bin/flutter precache --android --no-web --no-linux --no-ios --no-macos --no-fuchsia 2>/dev/null || true && \
    # Accept Android licenses through flutter
    /opt/flutter/bin/flutter doctor --android-licenses 2>/dev/null || true

# ──────────────────────────────────────────────
# Install noVNC (self-contained web VNC client)
# ──────────────────────────────────────────────
ENV NOVNC_HOME=/opt/novnc
RUN git clone --depth=1 --branch v1.4.0 https://github.com/novnc/noVNC.git "${NOVNC_HOME}" && \
    git clone --depth=1 https://github.com/novnc/websockify "${NOVNC_HOME}/utils/websockify" && \
    pip3 install --no-cache-dir numpy 2>/dev/null || true

# ──────────────────────────────────────────────
# Environment PATH
# ──────────────────────────────────────────────
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${PATH}"
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

# ──────────────────────────────────────────────
# User setup: create vscode user with sudo + docker group
# ──────────────────────────────────────────────
RUN groupadd --gid 1000 vscode && \
    useradd --uid 1000 --gid 1000 -m -s /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode && \
    # Grant ownership of SDKs
    chown -R vscode:vscode "${ANDROID_HOME}" 2>/dev/null || true && \
    chown -R vscode:vscode "${FLUTTER_HOME}" 2>/dev/null || true

USER vscode
WORKDIR /workspace/ghostkey

# ──────────────────────────────────────────────
# Flutter post-install: precache + doctor
# ──────────────────────────────────────────────
RUN flutter config --no-analytics 2>/dev/null && \
    flutter config --android-sdk "${ANDROID_HOME}" 2>/dev/null && \
    flutter precache --android --no-web --no-linux 2>/dev/null || true

CMD ["/bin/bash"]