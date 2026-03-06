#!/bin/bash

VERSION="1.0.1"
AUTHOR="Nitin Prakash"
EMAIL="nitinwebsiteexpert@gmail.com"

clear
echo "======================================================="
echo "        ShortsBuilder CLI - Splitter v$VERSION"
echo "        Author: $AUTHOR"
echo "        Support: $EMAIL"
echo "======================================================="
echo ""

############################################
# FFMPEG DETECTION (UNCHANGED)
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
# USER INPUT (UNCHANGED)
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

############################################
# COUNT TOTAL SEGMENTS (NEW)
############################################

total_segments=$(grep -cve '^\s*$' "$timestamps")
current_segment=0
total_time=0

echo ""
echo "Starting split process..."
echo "Total Segments: $total_segments"
echo ""

############################################
# SPLIT LOOP (LOGIC UNCHANGED)
############################################

while IFS= read -r line || [[ -n "$line" ]]; do

    [[ -z "$line" ]] && continue
    ((current_segment++))

    IFS='|' read -r timepart title <<< "$line"
    read -r start end <<< "$timepart"

    [[ -z "$title" ]] && title="${start//:/-}_to_${end//:/-}"
    safe_title=$(echo "$title" | tr -cd '[:alnum:] _-' | tr ' ' '_')
    output="$output_dir/$safe_title.mp4"

    percent=$((current_segment * 100 / total_segments))

    # ETA calculation
    if [[ $current_segment -gt 1 ]]; then
        avg=$((total_time / (current_segment - 1)))
        remaining=$(( (total_segments - current_segment + 1) * avg ))
        eta_display="$((remaining/60))m $((remaining%60))s"
    else
        eta_display="Calculating..."
    fi

    echo "▶ [$current_segment/$total_segments] ($percent%) Splitting: $safe_title"
    echo "   Estimated Remaining: $eta_display"

    start_time=$(date +%s)

    ffmpeg -nostdin -y -loglevel error \
        -i "$input" \
        -ss "$start" -to "$end" \
        -map 0:v -map 0:a \
        -c:v copy \
        -c:a aac -b:a 160k -ar 48000 \
        -movflags +faststart \
        "$output" > /dev/null 2>&1

    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    total_time=$((total_time + elapsed))

    echo "✔ Completed in ${elapsed}s"
    echo ""

done < "$timestamps"

echo "======================================================="
echo "Splitting completed."
echo "Total Time: $((total_time/60))m $((total_time%60))s"
echo "Output saved in: $output_dir"
echo "======================================================="