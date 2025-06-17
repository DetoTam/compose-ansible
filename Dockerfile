FROM python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    sshpass \
    openssh-client \
    curl \
    git \
    gcc \
    g++ \
    libffi-dev \
    libkrb5-dev \
    build-essential \
    python3-dev \
    && apt-get clean

# Install Ansible
RUN pip install --upgrade pip \
    && pip install ansible ansible-lint
RUN pip install --upgrade pip \
    && pip install ansible pywinrm[credssp] pywinrm[kerberos]

# Create working directory
WORKDIR /ansible

# Install additional components
RUN ansible-galaxy collection install community.general
RUN ansible-galaxy collection install ansible.posix
RUN ansible-galaxy collection install ansible.windows community.windows

CMD ["bash"]
