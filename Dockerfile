# Use the latest stable Ubuntu image
FROM nvidia/cuda:13.1.2-cudnn-devel-ubuntu24.04

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


# Start the SSH daemon in the foreground
CMD ["/usr/sbin/sshd", "-D"]

