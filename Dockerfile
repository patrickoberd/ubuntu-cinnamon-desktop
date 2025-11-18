# Ubuntu Cinnamon Desktop for Coder
# Beginner-friendly development environment with modern GUI

FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install core packages
RUN apt-get update && apt-get install -y \
    # Desktop environment
    cinnamon-desktop-environment \
    cinnamon-core \
    cinnamon-screensaver \
    nemo \
    gnome-terminal \
    # VNC server
    tigervnc-standalone-server \
    tigervnc-common \
    # X11 utilities
    x11-xserver-utils \
    xdg-utils \
    dbus-x11 \
    # Terminal & shell
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    # Development tools - Compilers
    build-essential \
    gcc \
    g++ \
    clang \
    make \
    cmake \
    ninja-build \
    # Development tools - Languages
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    nodejs \
    npm \
    golang-go \
    rustc \
    cargo \
    # Editors
    neovim \
    vim \
    gedit \
    # Version control
    git \
    git-lfs \
    # System utilities
    htop \
    btop \
    ncdu \
    tmux \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    # Modern CLI tools
    fzf \
    ripgrep \
    fd-find \
    bat \
    eza \
    # JSON/YAML tools
    jq \
    # SSH & sudo
    openssh-client \
    sudo \
    # Clipboard tools
    xclip \
    xsel \
    # File managers
    ranger \
    # GUI applications
    firefox \
    galculator \
    # Notification daemon (included in cinnamon)
    # Network tools
    net-tools \
    iproute2 \
    dnsutils \
    netcat-openbsd \
    # Fonts
    fonts-dejavu \
    fonts-liberation \
    fonts-noto \
    fonts-noto-color-emoji \
    # Screenshots & media
    feh \
    maim \
    imagemagick \
    # Archive tools
    unzip \
    zip \
    p7zip-full \
    # Application launcher
    rofi \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install FiraCode Nerd Font manually
RUN mkdir -p /usr/share/fonts/truetype/firacode-nerd && \
    cd /tmp && \
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip -o FiraCode.zip && \
    unzip FiraCode.zip -d /usr/share/fonts/truetype/firacode-nerd && \
    rm FiraCode.zip && \
    fc-cache -fv

# Install Docker CLI (not Docker daemon - workspaces use host Docker socket)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-compose-plugin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    chmod a+r /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Helm (direct binary download - more reliable than apt)
RUN HELM_VERSION=3.16.3 && \
    curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | tar -xz -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    rm -rf /tmp/linux-amd64

# Install noVNC for browser access
RUN mkdir -p /opt/noVNC /opt/websockify && \
    curl -L https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar -xz -C /opt/noVNC --strip-components=1 && \
    curl -L https://github.com/novnc/websockify/archive/v0.11.0.tar.gz | tar -xz -C /opt/websockify --strip-components=1 && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Install code-server (VS Code in browser)
RUN CODE_SERVER_VERSION=4.96.2 && \
    curl -fsSL "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz" | tar -xz -C /tmp && \
    mv "/tmp/code-server-${CODE_SERVER_VERSION}-linux-amd64" /usr/local/lib/code-server && \
    ln -s /usr/local/lib/code-server/bin/code-server /usr/local/bin/code-server

# Install miniserve (file server with upload support)
RUN MINISERVE_VERSION=0.28.0 && \
    curl -fsSL "https://github.com/svenstaro/miniserve/releases/download/v${MINISERVE_VERSION}/miniserve-${MINISERVE_VERSION}-x86_64-unknown-linux-musl" -o /usr/local/bin/miniserve && \
    chmod +x /usr/local/bin/miniserve

# Create user
RUN useradd -m -s /bin/zsh -G sudo coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install oh-my-zsh to /etc/skel (will be copied to home directory at runtime)
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /etc/skel/.oh-my-zsh && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /etc/skel/.oh-my-zsh/custom/themes/powerlevel10k

# Note: Coder agent is installed at runtime in start-desktop.sh
# This ensures the correct version is always used

# Create configuration directories
RUN mkdir -p /etc/skel/.config/cinnamon /etc/skel/.config/gtk-3.0 /etc/skel/.vnc

# Copy configuration files
COPY build/.zshrc /etc/skel/.zshrc
COPY build/.tmux.conf /etc/skel/.tmux.conf

# Copy startup and helper scripts
COPY build/start-desktop.sh /usr/local/bin/start-desktop.sh
COPY build/file-server.sh /usr/local/bin/file-server.sh
COPY build/screenshot.sh /usr/local/bin/screenshot.sh
COPY build/quick-launcher.sh /usr/local/bin/quick-launcher.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/start-desktop.sh && \
    chmod +x /usr/local/bin/file-server.sh && \
    chmod +x /usr/local/bin/screenshot.sh && \
    chmod +x /usr/local/bin/quick-launcher.sh

# Create Continue.dev configuration for AI coding assistant
RUN mkdir -p /etc/skel/.continue && \
    cat > /etc/skel/.continue/config.json << 'EOF'
{
  "models": [
    {
      "title": "Qwen 2.5 Coder 7B (Fast & Light)",
      "provider": "openai",
      "model": "qwen-coder-7b",
      "apiBase": "http://qwen-coder-7b-predictor.kserve-inference.svc.cluster.local/openai/v1",
      "apiKey": "dummy-key-not-required",
      "contextLength": 16384,
      "completionOptions": {
        "temperature": 0.2,
        "topP": 0.95,
        "maxTokens": 2048,
        "presencePenalty": 0.0,
        "frequencyPenalty": 0.0
      }
    },
    {
      "title": "DeepSeek Coder 6.7B (Best Quality)",
      "provider": "openai",
      "model": "deepseek-coder-6.7b",
      "apiBase": "http://deepseek-coder-6.7b-predictor.kserve-inference.svc.cluster.local/openai/v1",
      "apiKey": "dummy-key-not-required",
      "contextLength": 16384,
      "completionOptions": {
        "temperature": 0.2,
        "topP": 0.95,
        "maxTokens": 2048,
        "presencePenalty": 0.0,
        "frequencyPenalty": 0.0
      }
    },
    {
      "title": "StarCoder2 3B (619 Languages)",
      "provider": "openai",
      "model": "starcoder2-3b",
      "apiBase": "http://starcoder2-3b-predictor.kserve-inference.svc.cluster.local/openai/v1",
      "apiKey": "dummy-key-not-required",
      "contextLength": 16384,
      "completionOptions": {
        "temperature": 0.2,
        "topP": 0.95,
        "maxTokens": 2048,
        "presencePenalty": 0.0,
        "frequencyPenalty": 0.0
      }
    },
    {
      "title": "Yi Coder 9B (128K Context)",
      "provider": "openai",
      "model": "yi-coder-9b",
      "apiBase": "http://yi-coder-9b-predictor.kserve-inference.svc.cluster.local/openai/v1",
      "apiKey": "dummy-key-not-required",
      "contextLength": 32768,
      "completionOptions": {
        "temperature": 0.2,
        "topP": 0.95,
        "maxTokens": 2048,
        "presencePenalty": 0.0,
        "frequencyPenalty": 0.0
      }
    }
  ],
  "tabAutocompleteModel": {
    "title": "DeepSeek Coder 6.7B (Autocomplete)",
    "provider": "openai",
    "model": "deepseek-coder-6.7b",
    "apiBase": "http://deepseek-coder-6.7b-predictor.kserve-inference.svc.cluster.local/openai/v1",
    "apiKey": "dummy-key-not-required",
    "contextLength": 8192,
    "completionOptions": {
      "temperature": 0.1,
      "topP": 0.95,
      "maxTokens": 256,
      "presencePenalty": 0.0,
      "frequencyPenalty": 0.0
    }
  },
  "embeddingsProvider": {
    "provider": "transformers.js"
  },
  "slashCommands": [
    {
      "name": "edit",
      "description": "Edit selected code"
    },
    {
      "name": "comment",
      "description": "Add comments to code"
    },
    {
      "name": "share",
      "description": "Export conversation"
    },
    {
      "name": "cmd",
      "description": "Generate shell command"
    }
  ],
  "customCommands": [
    {
      "name": "test",
      "description": "Generate tests for the selected code",
      "prompt": "Generate comprehensive unit tests for this code:\n\n{{{ input }}}"
    },
    {
      "name": "optimize",
      "description": "Optimize the selected code",
      "prompt": "Analyze and suggest performance optimizations for this code:\n\n{{{ input }}}"
    },
    {
      "name": "explain",
      "description": "Explain the selected code",
      "prompt": "Explain how this code works in detail, including its purpose and key concepts:\n\n{{{ input }}}"
    },
    {
      "name": "docs",
      "description": "Generate documentation",
      "prompt": "Generate comprehensive documentation for this code:\n\n{{{ input }}}"
    }
  ],
  "allowAnonymousTelemetry": false,
  "docs": []
}
EOF

# Environment setup
ENV DISPLAY=:1
ENV HOME=/home/coder
ENV USER=coder
ENV SHELL=/bin/zsh
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

WORKDIR /home/coder
USER coder

# Expose VNC, noVNC, code-server, and file server ports
EXPOSE 5901 6080 8080 8888

CMD ["/usr/local/bin/start-desktop.sh"]
