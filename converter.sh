#!/bin/bash

VERSION="1.0.1"
AUTHOR="Nitin Prakash"

clear
echo "======================================================="
echo "        ShortsBuilder CLI - Converter v$VERSION"
echo "======================================================="

############################################
# FFMPEG CHECK
############################################

if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "❌ FFmpeg not installed"
    exit 1
fi

echo "✓ FFmpeg detected"
echo ""

############################################
# INPUT SOURCE
############################################

read -p "Enter video file or folder path: " source

if [[ ! -e "$source" ]]; then
    echo "❌ Path not found"
    exit 1
fi

############################################
# FORMAT
############################################

echo ""
echo "Output Format:"
echo "1) 3GP"
echo "2) MP4"
echo "3) MKV"

read -p "Select [1-3, default:1]: " format_choice
format_choice=${format_choice:-1}

case $format_choice in
2) format="mp4" ;;
3) format="mkv" ;;
*) format="3gp" ;;
esac

############################################
# PERFORMANCE
############################################

echo ""
echo "Performance:"
echo "1) Fast"
echo "2) Balanced"
echo "3) High Quality"

read -p "Select [1-3]: " perf
perf=${perf:-1}

case $perf in
2) preset="medium"; crf="22";;
3) preset="slow"; crf="18";;
*) preset="veryfast"; crf="26";;
esac

############################################
# FILE SIZE PRESET
############################################

echo ""
echo "File Size:"
echo "1) Large Quality"
echo "2) Medium"
echo "3) Small"

read -p "Select [1-3]: " size_mode
size_mode=${size_mode:-1}

case $size_mode in
2) crf=$((crf+2));;
3) crf=$((crf+4));;
esac

############################################
# SHORTS MODE
############################################

read -p "Convert to Shorts? (y/n): " shorts
shorts=${shorts:-n}

############################################
# CENTER SHIFT
############################################

shift_x="(iw-1080)/2"

if [[ "$shorts" == "y" ]]; then

echo ""
echo "Centering:"
echo "1) Center"
echo "2) Left"
echo "3) Right"
echo "4) Custom"

read -p "Select [1-4]: " center
center=${center:-1}

case $center in
2) shift_x="(iw*0.15)" ;;
3) shift_x="(iw*0.35)" ;;
4)
read -p "Enter shift percent (0-100): " percent
shift_x="(iw*0.$percent)"
;;
esac

fi

############################################
# COLLECT FILES
############################################

if [[ -d "$source" ]]; then
files=$(find "$source" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.avi" \) \
-not -path "*/shorts/*" -not -path "*/converted/*")
base_dir="$source"
else
files="$source"
base_dir=$(dirname "$source")
fi

############################################
# OUTPUT DIR
############################################

if [[ "$shorts" == "y" ]]; then
output_dir="$base_dir/shorts"
else
output_dir="$base_dir/converted"
fi

mkdir -p "$output_dir"

############################################
# SAFE NVENC DETECTION
############################################

if ffmpeg -hide_banner -f lavfi -i nullsrc -c:v h264_nvenc -f null - 2>/dev/null; then
encoder="nvenc"
echo "✓ NVENC GPU encoder active"
else
encoder="cpu"
echo "✓ NVENC not usable, using CPU encoder"
fi

############################################
# PROCESS LOOP
############################################

total=$(echo "$files" | wc -l)
count=0

for file in $files
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
echo "[$count/$total] ▶ Processing: $filename"

############################################
# VALIDATE INPUT FILE
############################################

if ! ffprobe "$file" &>/dev/null; then
echo "⚠ Skipping corrupted file"
continue
fi

if [[ -f "$output" ]]; then
echo "✓ Skipping existing"
continue
fi

############################################
# DETECT ORIENTATION
############################################

dimensions=$(ffprobe -v error -select_streams v:0 \
-show_entries stream=width,height \
-of csv=p=0 "$file")

width=$(echo $dimensions | cut -d',' -f1)
height=$(echo $dimensions | cut -d',' -f2)

############################################
# FILTER
############################################

if [[ "$shorts" == "y" && $height -lt $width ]]; then
filter="crop=1080:1920:${shift_x}:0"
else
filter="scale=iw:ih"
fi

############################################
# ENCODE
############################################

if [[ "$encoder" == "nvenc" ]]; then

ffmpeg -threads 0 -loglevel error \
-i "$file" \
-vf "$filter" \
-c:v h264_nvenc -preset p4 -cq $crf \
-c:a aac -b:a 160k \
-movflags +faststart \
"$output"

else

ffmpeg -threads 0 -loglevel error \
-i "$file" \
-vf "$filter" \
-c:v libx264 -preset $preset -crf $crf \
-c:a aac -b:a 160k \
-movflags +faststart \
"$output"

fi

############################################
# VERIFY OUTPUT
############################################

if [[ $? -eq 0 ]]; then
echo "✓ Completed"
else
echo "❌ Conversion failed"
rm -f "$output"
fi

done

echo ""
echo "=================================="
echo "Conversion completed"
echo "Output directory: $output_dir"
echo "=================================="