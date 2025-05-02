# Base image
FROM ubuntu:25.04

# Install essential tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    git \
    curl \
    unzip \
    nano \
    htop \
    xz-utils \
    python3-pip \
    libglu1-mesa \
    openjdk-17-jre \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Environment variables
ENV ANDROID_HOME=/usr/local/android-sdk
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/34.0.0:${PATH}"
ENV GRADLE_HOME=/usr/local/gradle
ENV PATH="${GRADLE_HOME}/gradle-8.1/bin:${PATH}"
ENV FLUTTER_HOME=/usr/local/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Install Flutter 3.29.3
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.3-stable.tar.xz -O flutter.tar.xz && \
    tar xf flutter.tar.xz -C /usr/local && \
    rm flutter.tar.xz

RUN git config --global --add safe.directory /usr/local/flutter

# Precache Flutter dependencies
RUN flutter doctor && flutter precache

# Install Gradle
RUN wget https://services.gradle.org/distributions/gradle-8.1-bin.zip && \
    unzip gradle-8.1-bin.zip -d /usr/local/gradle && \
    rm gradle-8.1-bin.zip

# Install Android SDK and required components
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    rm /tmp/cmdline-tools.zip && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    yes | sdkmanager --licenses && \
    sdkmanager \
    "platform-tools" \
    "platforms;android-31" \
    "platforms;android-34" \
    "platforms;android-35" \
    "build-tools;34.0.0" \
    "ndk;27.0.12077973" \
    "cmake;3.22.1"

# Create a temporary project to warm up Gradle and Flutter caches
RUN mkdir -p /tmp/flutter_project && \
    cd /tmp/flutter_project && \
    flutter create . && \
    flutter build apk --release --split-per-abi && \
    flutter clean && \
    cd / && \
    rm -rf /tmp/flutter_project

# Final doctor check
RUN flutter doctor
