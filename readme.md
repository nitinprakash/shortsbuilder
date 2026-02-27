# 🎬 ShortsBuilder CLI

**Version:** 1.0.0  
**Author:** NeeB Plugins  
**License:** MIT  

ShortsBuilder CLI is a professional yet simple command-line tool that helps you:

- Split large videos using timestamps
- Convert videos into lightweight formats (3GP default)
- Generate YouTube Shorts (Vertical 9:16)
- Batch process entire folders
- Maintain clean and efficient workflows

Designed for creators, educators, and content repurposers.

---

## 🚀 Features

- Automatic FFmpeg detection
- OS-specific installation guidance
- Default lightweight 3GP export
- YouTube Shorts (1080x1920)
- Center crop (default)
- Clean terminal output
- Professional structure
- Cross-platform support

---

## 🖥 Supported Platforms

| OS | Status |
|----|--------|
| Linux | Fully Tested |
| Windows (Git Bash / WSL) | Tested |
| macOS | Supported |

---

# 🔧 Installing FFmpeg

ShortsBuilder CLI requires FFmpeg.

## Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install ffmpeg
```

## macOS (Homebrew)

```bash
brew install ffmpeg
```

## Windows

1. Download FFmpeg from:
   https://www.gyan.dev/ffmpeg/builds/
2. Extract the ZIP file
3. Add the `bin` folder to your System PATH
4. Restart terminal

Verify installation:

```bash
ffmpeg -version
```

---

# 🛠 Usage

Make scripts executable:

```bash
chmod +x splitter.sh
chmod +x converter.sh
```

## Split Video

```bash
./splitter.sh
```

## Convert / Generate Shorts

```bash
./converter.sh
```

Follow on-screen instructions.

---

# 📁 Output Structure

Split files:
```
export/
```

Converted files:
```
converted/
```

Shorts:
```
shorts/
```

---

# 🔮 Future Improvements

- GPU acceleration
- AI speaker detection
- Subtitle burn-in
- Advanced CLI flag support

---

If this project helps you, consider giving it a ⭐ on GitHub.