# CUDA 12.1+ is recommended. cmake 3.28 required [default on ubuntu 24]
FROM nvidia/cuda:12.8.2-devel-ubuntu24.04

# Avoid prompts from apt during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install SSH server and sudo
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Required for the SSH daemon to run properly
RUN mkdir /var/run/sshd

# Create a non-root user 'devuser' with sudo
RUN useradd -m -s /bin/bash devuser && \
    adduser devuser sudo
RUN echo 'devuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set up the .ssh directory with correct permissions
RUN mkdir -p /home/devuser/.ssh && \
    chmod 700 /home/devuser/.ssh

# COPY your host's public key into the container's authorized_keys file
# Replace 'id_container.pub' with your actual public key filename if different
COPY gromacs_key.pub /home/devuser/.ssh/authorized_keys

# Fix ownership and permissions for the authorized_keys file
RUN chown -R devuser:devuser /home/devuser/.ssh && \
    chmod 600 /home/devuser/.ssh/authorized_keys

# Harden SSH configuration (Disable password login, enforce key login)
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config


# Set up SSH environment variables to prevent connection drops
RUN sed -i 's/#TCPKeepAlive yes/TCPKeepAlive yes/' /etc/ssh/sshd_config

# Expose port 22 inside the container
EXPOSE 22

# BEGIN GROMACS SECTION
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        curl \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/local/cuda-12.8 /usr/local/cuda && \
    mkdir -p /app && chown -R devuser:devuser /app

# Switch to the new user for all subsequent instructions
USER devuser
WORKDIR /app
COPY gromacs-2026.2.tar.gz gromacs-2026.2.tar.gz
RUN tar xfz gromacs-2026.2.tar.gz
RUN cd gromacs-2026.2
RUN mkdir build
RUN cd build
RUN cmake /app/gromacs-2026.2 -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON -DGMX_GPU=CUDA
RUN make
RUN make check
RUN sudo make install

RUN echo "PATH=$PATH:/app/bin" >> /home/devuser/.bashrc

# Start the SSH daemon in the foreground
CMD ["sudo","/usr/sbin/sshd", "-D"]
