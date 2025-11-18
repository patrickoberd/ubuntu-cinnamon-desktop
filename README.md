# Ubuntu XFCE Desktop for Coder

A beginner-friendly, full-featured Ubuntu desktop environment with modern XFCE desktop (Arc-Dark theme), accessible entirely from your browser. Perfect for learning to code, web development, or just having a familiar Linux desktop in the cloud!

## Why This Template?

- **No Linux knowledge required** - Works like Windows or Mac
- **Traditional desktop** - Familiar taskbar, start menu, and desktop icons
- **Point-and-click** - Mouse-driven interface, no keyboard shortcuts needed
- **Modern & elegant** - XFCE with Arc-Dark theme and Papirus icons
- **Lightweight** - Fast and responsive (~250MB RAM, works great in containers)
- **Fully equipped** - All development tools pre-installed and ready to use
- **AI-powered coding** - Built-in AI assistant (Continue.dev) for coding help

## What You Get

### Desktop Environment
- **XFCE Desktop** - Modern themed interface with Arc-Dark + Papirus icons
- **Browser Access** - No installation needed, access from any web browser
- **Persistent Storage** - Your files are saved between sessions
- **Customizable** - Choose your theme, resolution, timezone, and more

### Development Tools
- **Programming Languages**: Python 3, Node.js (JavaScript), Go, Rust, C/C++
- **Code Editors**:
  - VS Code (web version) with AI assistant
  - Neovim, Vim, gedit (simple text editor)
- **Version Control**: Git with GitHub integration
- **Containers**: Docker CLI, kubectl, Helm (for cloud applications)

### Pre-installed Applications
- **Firefox** - Web browser for testing and browsing
- **File Manager** (Nemo) - Browse and manage your files
- **Terminal** - Command line with helpful suggestions
- **Calculator** - Quick calculations
- **Screenshot Tool** - Capture your screen

### AI Coding Assistant (Continue.dev)
- **4 AI models** to choose from (optimized for code)
- **Tab autocomplete** - AI suggests code as you type
- **Chat interface** - Ask questions, explain code, generate tests
- **Works offline** - Uses your cluster's GPU resources
- **First time**: 10-15 minutes to start (GPU provisioning), then instant

## Quick Start

### Step 1: Get the Image

The Docker image is automatically built via GitHub Actions and published to GitHub Container Registry.

**First Time Setup** (Repository owner only):

1. **Enable GitHub Actions**:
   - Go to your repository: Settings → Actions → General
   - Under "Workflow permissions", select **"Read and write permissions"**
   - Save changes

2. **Push code** to trigger build:
   ```bash
   git push origin main
   ```

3. **Wait for build** (~10-15 minutes):
   - Go to Actions tab in GitHub
   - Watch the build complete

4. **Make package public**:
   - Go to https://github.com/users/YOUR_USERNAME/packages
   - Click `ubuntu-cinnamon-desktop`
   - Package settings → Change visibility to **Public**

### Step 2: Create Coder Template

```bash
# Login to your Coder instance
coder login https://coder.example.com

# Navigate to the template directory
cd coder-templates/ubuntu-cinnamon-desktop

# Create the template
coder templates create ubuntu-cinnamon-desktop \
  --directory . \
  --name "Ubuntu XFCE Desktop"

# Or update existing template
coder templates push ubuntu-cinnamon-desktop --directory .
```

### Step 3: Create Your Workspace

1. Go to your Coder dashboard
2. Click **"Create Workspace"**
3. Select **"Ubuntu XFCE Desktop"** template
4. Choose your preferences:
   - **CPU**: 2-4 cores (4 cores recommended for smooth experience)
   - **Memory**: 4-8 GB (2GB minimum for XFCE, 4GB recommended)
   - **Disk**: 20+ GB (based on your needs)
   - **Resolution**: Your screen resolution
   - **Theme**: Dark or Light
5. Click **"Create"**
6. Wait 1-2 minutes for workspace to start (first time: up to 30-40 minutes for image download)

### Step 4: Access Your Desktop

1. Click **"🖥️ Desktop (noVNC)"** in the Coder dashboard
2. Your Ubuntu desktop opens in a new browser tab
3. You're ready to go!

## Using Your Desktop

### Finding Applications

**Start Menu** (bottom-left):
- Click the menu icon in the bottom-left corner
- Browse categories or search for applications
- Click to launch

**Quick Launch Panel** (bottom taskbar):
- Terminal, Firefox, File Manager icons are pinned for quick access
- Click once to open

**Desktop Icons**:
- Double-click "Home" to open your files
- Double-click "Computer" to browse system

### Common Tasks

#### Opening a Terminal
- **Click**: Terminal icon in bottom panel
- **Or**: Start Menu → Terminal
- **Keyboard**: Ctrl+Alt+T

#### Installing Software
Ubuntu uses `apt` (package manager). Open terminal and type:
```bash
# Search for software
apt search <name>

# Install software (example: installing VLC media player)
sudo apt install vlc

# Update all software
sudo apt update && sudo apt upgrade
```

#### Managing Files
- **Open File Manager**: Click "Files" icon or double-click "Home" on desktop
- **Create folder**: Right-click → Create Folder
- **Copy/Paste**: Right-click → Copy, then right-click → Paste
- **Upload files**: Click "📁 Files" app in Coder dashboard, drag and drop

#### Taking Screenshots
- **Full screen**: Press `Print` key
- **Select area**: Use Start Menu → Screenshot tool
- **Quick access**: Right-click desktop → Screenshot

#### Using VS Code with AI
1. Click **"📝 VS Code"** in Coder dashboard (or open Firefox → http://localhost:8080)
2. Click Continue.dev icon in left sidebar (chat bubble)
3. Press `Ctrl+L` to open AI chat
4. Ask questions like:
   - "Explain this code"
   - "Write a function to sort a list"
   - "Find bugs in my code"
   - "Generate tests for this function"
5. Tab autocomplete works automatically as you type

### Customizing Your Desktop

**Change Theme** (after creating workspace):
1. Stop workspace
2. Click workspace name → Settings
3. Change "Desktop Theme" to Light or Dark
4. Start workspace - theme is applied automatically

**Change Resolution**:
1. Same as above - change "Desktop Resolution"
2. Or use Start Menu → Display Settings

**Change Panel Position** (taskbar):
1. Stop workspace → Settings → "Taskbar Position"
2. Choose Bottom (Windows-style) or Top (macOS-style)

## Tips for Beginners

### 1. Save Your Work
- All files in your **Home folder** (`/home/coder`) are saved permanently
- Files outside Home folder are lost when workspace restarts
- Use File Manager to stay in Home folder

### 2. Terminal is Powerful
Don't be intimidated! The terminal helps you:
- Install software faster
- Manage files efficiently
- Use development tools
- Learn Linux commands

Common commands:
```bash
ls              # List files in current folder
cd projects     # Change to projects folder
cd ..           # Go up one folder
mkdir newfolder # Create new folder
pwd             # Show current location
```

### 3. Use the AI Assistant
The Continue.dev AI is your coding buddy:
- Stuck on a problem? Ask it!
- Need code explained? Select it and ask "explain this"
- Want to learn? Ask "teach me how to..."
- Writing tests? Ask "generate tests for this function"

### 4. Firefox is Pre-installed
- Test your web applications
- Browse documentation
- Access external services
- Open localhost:8080 for VS Code

### 5. Everything Resets Except Home
When you restart your workspace:
- ✅ Files in `/home/coder` are kept
- ✅ Installed software in your home directory stays
- ❌ System-wide installed software is lost (unless in Dockerfile)
- ❌ Desktop customizations beyond parameters reset

## Troubleshooting

### Desktop not loading

**Black screen or stuck loading**:
1. Wait 2-3 minutes (services may still be starting)
2. Refresh browser page
3. Check workspace logs in Coder dashboard
4. Try stopping and starting workspace

### VS Code not opening

**Browser says "Connection refused"**:
1. Desktop must be running first (click Desktop app, wait for it to load)
2. Then open VS Code app
3. Or open Firefox from desktop → http://localhost:8080

### AI not responding

**Continue.dev says "Loading..." forever**:
- **First time**: GPU provisioning takes 10-15 minutes, be patient!
- KServe automatically buffers your request
- Subsequent requests are instant
- Check cluster has GPU nodes available

### Can't upload files

**File server not working**:
1. Open Terminal in Coder dashboard
2. Run: `/usr/local/bin/file-server.sh start`
3. Click "📁 Files" app in Coder dashboard
4. Drag and drop files to upload

### Software installation fails

**`apt install` says permission denied**:
- Use `sudo` before commands: `sudo apt install <package>`
- Example: `sudo apt install htop`
- Your user has full sudo access (no password needed)

## Resource Usage

**Minimum Requirements**:
- **CPU**: 2 cores
- **Memory**: 2 GB (XFCE desktop needs ~250MB)
- **Disk**: 20 GB

**Recommended for smooth experience**:
- **CPU**: 4 cores (for compiling code and running multiple apps)
- **Memory**: 4-8 GB (for large projects and multiple applications)
- **Disk**: 50-100 GB (for projects, dependencies, and downloads)

## Getting Help

### Learning Resources
- **Ubuntu Documentation**: https://help.ubuntu.com/
- **XFCE Desktop Guide**: https://docs.xfce.org/
- **VS Code Docs**: https://code.visualstudio.com/docs
- **Continue.dev Docs**: https://continue.dev/docs

### Common Questions

**Q: Can I install my own software?**
A: Yes! Use `sudo apt install <package-name>`. Search with `apt search`.

**Q: Will my files be saved?**
A: Yes, everything in `/home/coder` (your Home folder) is persistent.

**Q: Can I access this from my phone/tablet?**
A: Yes! noVNC works on mobile browsers, though desktop is best on larger screens.

**Q: How do I share files between my computer and workspace?**
A: Click "📁 Files" app in Coder → drag and drop files to upload or download.

**Q: Can I use this for production work?**
A: Yes! Many developers use cloud desktops for daily work. Remember to commit code to Git.

## Contributing

Want to improve this template?
- Add more pre-installed tools
- Improve the documentation
- Create custom desktop themes
- Share beginner-friendly tutorials

## License

This template is provided as-is for use with Coder. Free to modify and distribute!

## You're All Set!

Enjoy your Ubuntu desktop in the cloud! Remember:
- **No Linux experience needed** - point, click, and explore
- **AI assistant is your friend** - ask it anything about code
- **Files in Home folder are saved** - work with confidence
- **Community is helpful** - don't hesitate to ask questions

Happy coding! 🚀
