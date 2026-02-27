#!/bin/bash

VERSION="1.0.0"
AUTHOR="Nitin Prakash"
EMAIL="nitinwebsiteexpert@gmail.com"

clear
echo "======================================================="
echo "        ShortsBuilder CLI - Converter v$VERSION"
echo "        Author: $AUTHOR"
echo "        Support: $EMAIL"
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

read -p "Enter video file OR folder path: " source
[[ ! -e "$source" ]] && echo "❌ Path not found." && exit 1

echo ""
echo "Choose Output Format:"
echo "1. 3GP (Default)"
echo "2. MP4"
echo "3. MKV"
read -p "Select option [1-3, default: 1]: " format_choice
format_choice=${format_choice:-1}

case $format_choice in
    2) format="mp4" ;;
    3) format="mkv" ;;
    *) format="3gp" ;;
esac

read -p "Convert to YouTube Shorts? (y/n, default: n): " shorts_mode
shorts_mode=${shorts_mode:-n}

if [[ -d "$source" ]]; then
    base_dir="$source"
    files=("$source"/*.{mp4,mkv,mov,avi})
else
    base_dir="$(dirname "$source")"
    files=("$source")
fi

if [[ "$shorts_mode" == "y" ]]; then
    output_dir="$base_dir/shorts"
else
    output_dir="$base_dir/converted"
fi

mkdir -p "$output_dir"

total_files=0
for f in "${files[@]}"; do
    [[ -f "$f" ]] && ((total_files++))
done

echo ""
echo "Processing $total_files file(s)..."

for file in "${files[@]}"; do

    [[ ! -f "$file" ]] && continue

    filename=$(basename "$file")
    name="${filename%.*}"

    if [[ "$shorts_mode" == "y" ]]; then
        output="$output_dir/shorts_${name}.${format}"
    else
        output="$output_dir/${name}.${format}"
    fi

    echo "▶ Processing: $filename"

    if [[ "$shorts_mode" == "y" ]]; then
        filter_complex="crop=1080:1920:(iw-1080)/2:0,scale=1080:1920"

        ffmpeg -nostdin -y -loglevel error \
            -i "$file" \
            -filter_complex "$filter_complex" \
            -c:v libx264 -preset veryfast -crf 22 \
            -profile:v high -level 4.2 -pix_fmt yuv420p \
            -c:a aac -b:a 160k -ar 48000 \
            "$output" > /dev/null 2>&1
    else
        ffmpeg -nostdin -y -loglevel error \
            -i "$file" \
            -c:v libx264 -preset veryfast -crf 22 \
            -c:a aac -b:a 160k -ar 48000 \
            "$output" > /dev/null 2>&1
    fi

    echo "✔ Done"

done

echo ""
echo "All files processed."
echo "Output saved in: $output_dir"