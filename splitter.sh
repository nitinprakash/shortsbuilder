#!/bin/bash

VERSION="1.0.0"
AUTHOR="Nitin Prakash"

clear
echo "======================================================="
echo "        ShortsBuilder CLI - Splitter v$VERSION"
echo "        Author: $AUTHOR"
echo "======================================================="
echo ""

############################################
# FFMPEG DETECTION
############################################

detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="Linux" ;;
        Darwin*)    OS="macOS" ;;
        CYGWIN*|MINGW*|MSYS*) OS="Windows" ;;
        *)          OS="Unknown" ;;
    esac
}

show_install_instructions() {
    echo ""
    echo "FFmpeg is not installed."
    echo "Please install FFmpeg before using ShortsBuilder CLI."
    echo ""

    detect_os

    case "$OS" in
        Linux)
            echo "Ubuntu/Debian:"
            echo "  sudo apt update"
            echo "  sudo apt install ffmpeg"
            ;;
        macOS)
            echo "Install via Homebrew:"
            echo "  brew install ffmpeg"
            ;;
        Windows)
            echo "Windows Installation:"
            echo "1. Download from: https://www.gyan.dev/ffmpeg/builds/"
            echo "2. Extract ZIP"
            echo "3. Add the 'bin' folder to System PATH"
            ;;
        *)
            echo "Visit: https://ffmpeg.org/download.html"
            ;;
    esac

    exit 1
}

if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    show_install_instructions
fi

echo "FFmpeg detected:"
ffmpeg -version | head -n 1
echo ""

############################################
# USER INPUT
############################################

read -p "Enter input video file [default: input.mp4]: " input
input=${input:-input.mp4}

read -p "Enter output directory [default: export]: " output_dir
output_dir=${output_dir:-export}

read -p "Enter timestamps file [default: timestamps.txt]: " timestamps
timestamps=${timestamps:-timestamps.txt}

if [[ ! -f "$input" ]]; then
    echo "❌ Input video not found."
    exit 1
fi

if [[ ! -f "$timestamps" ]]; then
    echo "❌ Timestamps file not found."
    exit 1
fi

mkdir -p "$output_dir"

echo ""
echo "Starting split process..."
echo ""

while IFS= read -r line || [[ -n "$line" ]]; do

    [[ -z "$line" ]] && continue

    IFS='|' read -r timepart title <<< "$line"
    read -r start end <<< "$timepart"

    [[ -z "$title" ]] && title="${start//:/-}_to_${end//:/-}"
    safe_title=$(echo "$title" | tr -cd '[:alnum:] _-' | tr ' ' '_')
    output="$output_dir/$safe_title.mp4"

    echo "▶ Splitting: $safe_title"

    ffmpeg -nostdin -y -loglevel error \
        -i "$input" \
        -ss "$start" -to "$end" \
        -map 0:v -map 0:a \
        -c:v copy \
        -c:a aac -b:a 160k -ar 48000 \
        -movflags +faststart \
        "$output" > /dev/null 2>&1

    echo "✔ Done"

done < "$timestamps"

echo ""
echo "Splitting completed."
echo "Output saved in: $output_dir"