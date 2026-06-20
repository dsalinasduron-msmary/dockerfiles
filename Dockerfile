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

# Create a non-root user 'sshuser' with password 'password123'
RUN useradd -m -s /bin/bash sshuser && \
    echo 'sshuser:password123' | chpasswd && \
    adduser sshuser sudo

# (Optional) Allow root login via password if needed
# RUN echo 'root:rootpassword' | chpasswd
# RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Set up SSH environment variables to prevent connection drops
RUN sed -i 's/#TCPKeepAlive yes/TCPKeepAlive yes/' /etc/ssh/sshd_config

# Expose port 22 inside the container
EXPOSE 22

# Start the SSH daemon in the foreground
CMD ["/usr/sbin/sshd", "-D"]

