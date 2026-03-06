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

if ! command -v ffmpeg &> /dev/null; then
    echo "❌ FFmpeg not installed."
    echo "Install using:"
    echo "sudo apt install ffmpeg"
    exit 1
fi

echo "✓ FFmpeg detected"
echo ""

############################################
# SOURCE INPUT
############################################

read -p "Enter video file OR folder path: " source

if [[ ! -e "$source" ]]; then
    echo "❌ Path not found"
    exit 1
fi

############################################
# FORMAT
############################################

echo ""
echo "Choose Output Format:"
echo "1) 3GP (Default)"
echo "2) MP4"
echo "3) MKV"

read -p "Select option [1-3]: " format_choice
format_choice=${format_choice:-1}

case $format_choice in
2) format="mp4" ;;
3) format="mkv" ;;
*) format="3gp" ;;
esac

############################################
# PERFORMANCE PRESET
############################################

echo ""
echo "Choose Performance Preset:"
echo "1) Fast (Recommended)"
echo "2) Balanced"
echo "3) High Quality"

read -p "Select option [1-3]: " perf
perf=${perf:-1}

case $perf in
2)
preset="medium"
crf="22"
;;
3)
preset="slow"
crf="18"
;;
*)
preset="veryfast"
crf="24"
;;
esac

############################################
# SHORTS MODE
############################################

echo ""
read -p "Convert to YouTube Shorts? (y/n): " shorts
shorts=${shorts:-n}

############################################
# CENTERING OPTIONS
############################################

shift_x="(iw-1080)/2"

if [[ "$shorts" == "y" ]]; then

echo ""
echo "Horizontal Centering Options:"
echo "1) Center (Default)"
echo "2) Shift Left"
echo "3) Shift Right"
echo "4) Custom Percentage"

read -p "Choose option [1-4]: " center
center=${center:-1}

case $center in
2)
shift_x="(iw*0.15)"
;;
3)
shift_x="(iw*0.35)"
;;
4)
read -p "Enter horizontal shift percent (0-100): " percent
shift_x="(iw*0.$percent)"
;;
*)
shift_x="(iw-1080)/2"
;;
esac

fi

############################################
# RESOLUTION
############################################

echo ""
echo "Resolution Presets:"
echo "1) 1080x1920 (YouTube Shorts)"
echo "2) 720x1280"
echo "3) Keep Original"

read -p "Choose option [1-3]: " res
res=${res:-1}

case $res in
2)
scale="scale=720:1280"
;;
3)
scale="scale=iw:ih"
;;
*)
scale="scale=1080:1920"
;;
esac

############################################
# FILE COLLECTION
############################################

if [[ -d "$source" ]]; then
    files=("$source"/*.{mp4,mkv,mov,avi})
    base_dir="$source"
else
    files=("$source")
    base_dir=$(dirname "$source")
fi

############################################
# OUTPUT DIRECTORY
############################################

if [[ "$shorts" == "y" ]]; then
output_dir="$base_dir/shorts"
else
output_dir="$base_dir/converted"
fi

mkdir -p "$output_dir"

############################################
# PROCESS FILES
############################################

count=0

for file in "${files[@]}"
do

[[ ! -f "$file" ]] && continue

((count++))

filename=$(basename "$file")
name="${filename%.*}"

if [[ "$shorts" == "y" ]]; then
output="$output_dir/shorts_${name}.${format}"
else
output="$output_dir/${name}.${format}"
fi

echo ""
echo "[$count] ▶ Processing: $filename"

if [[ "$shorts" == "y" ]]; then

filter="crop=1080:1920:${shift_x}:0,$scale"

ffmpeg -loglevel error \
-i "$file" \
-vf "$filter" \
-c:v libx264 -preset $preset -crf $crf \
-c:a aac -b:a 160k \
"$output"

else

ffmpeg -loglevel error \
-i "$file" \
-c:v libx264 -preset $preset -crf $crf \
-c:a aac -b:a 160k \
"$output"

fi

echo "✓ Completed"

done

echo ""
echo "=================================="
echo "All files processed."
echo "Output saved to:"
echo "$output_dir"
echo ""