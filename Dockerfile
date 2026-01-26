# OPERA Docker Container - Unified CL, Par, and UI Version
# Build with: docker build --build-arg VERSION=cl -t opera:cl .
#         or: docker build --build-arg VERSION=par -t opera:par .
#         or: docker build --build-arg VERSION=ui -t opera:ui .
#         or: ./build.sh [cl|par|ui|all]

ARG VERSION=cl

FROM ubuntu:22.04

ARG VERSION

ENV DEBIAN_FRONTEND=noninteractive \
    OPERA_HOME=/usr/local/OPERA \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Install base dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    tar \
    xz-utils \
    ca-certificates \
    openjdk-11-jre \
    libxt6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libxrandr2 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Install UI-specific dependencies
RUN if [ "$VERSION" = "ui" ]; then \
    apt-get update && apt-get install -y \
        libgtk2.0-0 \
        libgdk-pixbuf2.0-0 \
        libxdamage1 \
        libgbm1 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libasound2 \
        libnss3 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libxcomposite1 \
        libswt-gtk-4-java \
        x11-apps \
        xauth \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Install Xvfb for PAR version (needed for Matlab parallel pool)
RUN if [ "$VERSION" = "par" ]; then \
    apt-get update && apt-get install -y xvfb && rm -rf /var/lib/apt/lists/*; \
    fi

# Create directories
RUN mkdir -p ${OPERA_HOME} /data/input /data/output

# Download latest OPERA installer from GitHub based on VERSION
RUN if [ "$VERSION" = "ui" ]; then \
        wget -O /tmp/OPERA_mcr.tar.xz $(wget -qO- https://api.github.com/repos/kmansouri/OPERA/releases/latest | grep "browser_download_url.*UI_mcr.tar.xz" | cut -d '"' -f 4); \
    elif [ "$VERSION" = "par" ]; then \
        wget -O /tmp/OPERA_mcr.tar.xz $(wget -qO- https://api.github.com/repos/kmansouri/OPERA/releases/latest | grep "browser_download_url.*CL_Par.tar.xz" | cut -d '"' -f 4); \
    else \
        wget -O /tmp/OPERA_mcr.tar.xz $(wget -qO- https://api.github.com/repos/kmansouri/OPERA/releases/latest | grep "browser_download_url.*CL_mcr.tar.xz" | cut -d '"' -f 4); \
    fi

# Extract and install
RUN cd /tmp && \
    tar -xf OPERA_mcr.tar.xz && \
    cd OPERA*/OPERA* && \
    find . -maxdepth 1 -name "*.install" -exec {} -mode silent -agreeToLicense yes -destinationFolder ${OPERA_HOME} \; && \
    rm -rf /tmp/OPERA* && \
    chmod -R 777 ${OPERA_HOME}/application/knime_*/configuration && \
    chmod -R 777 ${OPERA_HOME}/application/knime_*/knime-workspace

# Set environment variables for OPERA
ENV PATH="${OPERA_HOME}/application:${PATH}" \
    LD_LIBRARY_PATH="${OPERA_HOME}/v912/bin/glnxa64:${OPERA_HOME}/v912/runtime/glnxa64:${OPERA_HOME}/v912/sys/os/glnxa64:${OPERA_HOME}/v912/sys/opengl/lib/glnxa64"

# CL and PAR specific configuration
RUN if [ "$VERSION" = "cl" ] || [ "$VERSION" = "par" ]; then \
        echo "/usr/local/OPERA/application" > ${OPERA_HOME}/application/OPERA_installdir.txt && \
        if [ -d "${OPERA_HOME}/application/knime_4.5.1/knime-workspace/QSAR-ready_2.5.10" ]; then \
            find ${OPERA_HOME}/application/knime_4.5.1/knime-workspace/QSAR-ready_2.5.10 -name "settings.xml" -type f -exec sed -i 's|/root/Sample_input|/data/input|g' {} \; && \
            find ${OPERA_HOME}/application/knime_4.5.1/knime-workspace/QSAR-ready_2.5.10 -name "settings.xml" -type f -exec sed -i 's|Sample_50\.sdf|input\.sdf|g' {} \; ; \
        fi && \
        echo '#!/bin/bash' > /usr/local/bin/opera-wrapper.sh && \
        echo '# Function to fix MCR cache' >> /usr/local/bin/opera-wrapper.sh && \
        echo 'fix_mcr_cache() {' >> /usr/local/bin/opera-wrapper.sh && \
        echo '  while true; do' >> /usr/local/bin/opera-wrapper.sh && \
        echo '    if [ -d "/root/.mcrCache9.12" ]; then' >> /usr/local/bin/opera-wrapper.sh && \
        echo '      CACHE_DIR=$(find /root/.mcrCache9.12 -maxdepth 1 -type d -name "OPERA*" 2>/dev/null | head -n 1)' >> /usr/local/bin/opera-wrapper.sh && \
        echo '      if [ -n "$CACHE_DIR" ]; then' >> /usr/local/bin/opera-wrapper.sh && \
        echo '        echo "/usr/local/OPERA/application" > "/root/.mcrCache9.12/OPERA_installdir.txt"' >> /usr/local/bin/opera-wrapper.sh && \
        echo '        echo "/usr/local/OPERA/application" > "$CACHE_DIR/OPERA_installdir.txt"' >> /usr/local/bin/opera-wrapper.sh && \
        echo '        break' >> /usr/local/bin/opera-wrapper.sh && \
        echo '      fi' >> /usr/local/bin/opera-wrapper.sh && \
        echo '    fi' >> /usr/local/bin/opera-wrapper.sh && \
        echo '    sleep 0.1' >> /usr/local/bin/opera-wrapper.sh && \
        echo '  done' >> /usr/local/bin/opera-wrapper.sh && \
        echo '}' >> /usr/local/bin/opera-wrapper.sh && \
        echo '# Start background process to fix MCR cache' >> /usr/local/bin/opera-wrapper.sh && \
        echo 'fix_mcr_cache &' >> /usr/local/bin/opera-wrapper.sh && \
        echo '# Run OPERA' >> /usr/local/bin/opera-wrapper.sh && \
        if [ "$VERSION" = "par" ]; then \
            echo 'cd /usr/local/OPERA/application' >> /usr/local/bin/opera-wrapper.sh && \
            echo 'exec ./run_OPERA_P.sh /usr/local/OPERA/v912 "$@"' >> /usr/local/bin/opera-wrapper.sh; \
        else \
            echo 'cd /usr/local/OPERA/application' >> /usr/local/bin/opera-wrapper.sh && \
            echo 'exec ./OPERA "$@"' >> /usr/local/bin/opera-wrapper.sh; \
        fi && \
        chmod +x /usr/local/bin/opera-wrapper.sh; \
    fi

# UI-specific configuration
RUN if [ "$VERSION" = "ui" ]; then \
        mkdir -p /usr/local/bin/OPERA && \
        ln -s /usr/local/OPERA/application /usr/local/bin/OPERA/application; \
    fi

WORKDIR /data

# Set entrypoint based on version
RUN if [ "$VERSION" = "ui" ]; then \
        echo '#!/bin/bash' > /entrypoint.sh && \
        echo 'export _JAVA_OPTIONS="-Djava.awt.headless=false"' >> /entrypoint.sh && \
        echo 'exec /usr/local/OPERA/application/run_OPERA_UI.sh /usr/local/OPERA/v912 "$@"' >> /entrypoint.sh && \
        chmod +x /entrypoint.sh; \
    elif [ "$VERSION" = "par" ]; then \
        echo '#!/bin/bash' > /entrypoint.sh && \
        echo 'export DISPLAY=:99' >> /entrypoint.sh && \
        echo 'Xvfb :99 -screen 0 1024x768x24 &' >> /entrypoint.sh && \
        echo 'sleep 1' >> /entrypoint.sh && \
        echo 'exec /usr/local/bin/opera-wrapper.sh "$@"' >> /entrypoint.sh && \
        chmod +x /entrypoint.sh; \
    else \
        echo '#!/bin/bash' > /entrypoint.sh && \
        echo 'export _JAVA_OPTIONS="-Djava.awt.headless=true"' >> /entrypoint.sh && \
        echo 'exec /usr/local/bin/opera-wrapper.sh "$@"' >> /entrypoint.sh && \
        chmod +x /entrypoint.sh; \
    fi

ENTRYPOINT ["/entrypoint.sh"]
CMD []
