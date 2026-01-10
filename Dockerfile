# OPERA Docker Container - Using Pre-compiled OPERA Installer
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    OPERA_HOME=/usr/local/OPERA \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
    _JAVA_OPTIONS="-Djava.awt.headless=true"

# Install dependencies
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

# Create directories
RUN mkdir -p ${OPERA_HOME} /data/input /data/output

# Copy and extract OPERA installer
COPY OPERA2.9_CL_mcr.tar.xz /tmp/

# Extract and install
RUN cd /tmp && \
    tar -xf OPERA2.9_CL_mcr.tar.xz && \
    cd OPERA2.9_CL_mcr/OPERA2_CL_mcr && \
    ./OPERA2.9_mcr_Installer.install -mode silent -agreeToLicense yes -destinationFolder ${OPERA_HOME} && \
    rm -rf /tmp/OPERA* && \
    chmod -R 777 ${OPERA_HOME}/application/knime_4.5.1/configuration && \
    chmod -R 777 ${OPERA_HOME}/application/knime_4.5.1/knime-workspace

# Set environment variables for OPERA
ENV PATH="${OPERA_HOME}/application:${PATH}" \
    LD_LIBRARY_PATH="${OPERA_HOME}/v912/bin/glnxa64:${OPERA_HOME}/v912/runtime/glnxa64:${OPERA_HOME}/v912/sys/os/glnxa64:${OPERA_HOME}/v912/sys/opengl/lib/glnxa64"

# Create OPERA_installdir.txt file to fix installation path issue
RUN echo "/usr/local/OPERA/application" > ${OPERA_HOME}/application/OPERA_installdir.txt

# Modify QSAR-ready workflow to accept input from /data directory
RUN if [ -d "${OPERA_HOME}/application/knime_4.5.1/knime-workspace/QSAR-ready_2.5.10" ]; then \
    find ${OPERA_HOME}/application/knime_4.5.1/knime-workspace/QSAR-ready_2.5.10 -name "settings.xml" -type f -exec sed -i 's|/root/Sample_input|/data/input|g' {} \; && \
    find ${OPERA_HOME}/application/knime_4.5.1/knime-workspace/QSAR-ready_2.5.10 -name "settings.xml" -type f -exec sed -i 's|Sample_50\.sdf|input\.sdf|g' {} \; ; \
    fi

# Create wrapper script to fix MCR cache path issue
RUN echo '#!/bin/bash' > /usr/local/bin/opera-wrapper.sh && \
    echo '# Function to fix MCR cache' >> /usr/local/bin/opera-wrapper.sh && \
    echo 'fix_mcr_cache() {' >> /usr/local/bin/opera-wrapper.sh && \
    echo '  while true; do' >> /usr/local/bin/opera-wrapper.sh && \
    echo '    if [ -d "/root/.mcrCache9.12/OPERA_0" ]; then' >> /usr/local/bin/opera-wrapper.sh && \
    echo '      echo "/usr/local/OPERA/application" > "/root/.mcrCache9.12/OPERA_installdir.txt"' >> /usr/local/bin/opera-wrapper.sh && \
    echo '      break' >> /usr/local/bin/opera-wrapper.sh && \
    echo '    fi' >> /usr/local/bin/opera-wrapper.sh && \
    echo '    sleep 0.1' >> /usr/local/bin/opera-wrapper.sh && \
    echo '  done' >> /usr/local/bin/opera-wrapper.sh && \
    echo '}' >> /usr/local/bin/opera-wrapper.sh && \
    echo '# Start background process to fix MCR cache' >> /usr/local/bin/opera-wrapper.sh && \
    echo 'fix_mcr_cache &' >> /usr/local/bin/opera-wrapper.sh && \
    echo '# Run OPERA' >> /usr/local/bin/opera-wrapper.sh && \
    echo 'exec /usr/local/OPERA/application/OPERA "$@"' >> /usr/local/bin/opera-wrapper.sh && \
    chmod +x /usr/local/bin/opera-wrapper.sh

WORKDIR /data

# Entrypoint to OPERA wrapper script
ENTRYPOINT ["/usr/local/bin/opera-wrapper.sh"]
CMD ["-h"]