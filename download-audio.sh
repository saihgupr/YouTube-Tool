#!/bin/bash

# YouTube Audio Downloader
# Downloads audio from YouTube videos using yt-dlp
# 
# Usage:
#   ./download-audio.sh [video_ids...]           # Download specific videos
#   ./download-audio.sh --url "playlist_url"     # Download from watch_videos URL
#   ./download-audio.sh --file ids.txt           # Read video IDs from file
#   ./download-audio.sh --channel "channel_name" # Download from channel (uses app)
#
# Options:
#   --output, -o DIR    Output directory (default: ~/Music/YouTube)
#   --format, -f FMT    Audio format: mp3, m4a, opus, wav (default: mp3)
#   --quality, -q NUM   Audio quality: 0=best, 9=worst (default: 0)
#   --help, -h          Show this help message

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
OUTPUT_DIR="${HOME}/Music/YouTube"
FORMAT="mp3"
QUALITY="0"
VIDEO_IDS=()

# Print colored message
print_msg() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
}

# Print help
show_help() {
    cat << 'EOF'
YouTube Audio Downloader
========================

Downloads audio from YouTube videos using yt-dlp.

USAGE:
  ./download-audio.sh [OPTIONS] [VIDEO_IDS...]

OPTIONS:
  --url, -u URL       Extract video IDs from a watch_videos URL
  --file, -f FILE     Read video IDs from a file (one per line)
  --output, -o DIR    Output directory (default: ~/Music/YouTube)
  --format, -F FMT    Audio format: mp3, m4a, opus, wav (default: mp3)
  --quality, -q NUM   Audio quality for mp3: 0=best, 9=worst (default: 0)
  --help, -h          Show this help message

EXAMPLES:
  # Download specific videos
  ./download-audio.sh dQw4w9WgXcQ oHg5SJYRHA0

  # Download from playlist URL (from YouTube Tool app)
  ./download-audio.sh --url "https://www.youtube.com/watch_videos?video_ids=id1,id2,id3"

  # Read from file
  ./download-audio.sh --file video_ids.txt

  # Specify output folder and format
  ./download-audio.sh -o ~/Downloads/Music -F m4a dQw4w9WgXcQ

REQUIREMENTS:
  - yt-dlp: brew install yt-dlp
  - ffmpeg: brew install ffmpeg (for audio conversion)

EOF
    exit 0
}

# Check dependencies
check_dependencies() {
    local missing=()
    
    if ! command -v yt-dlp &> /dev/null; then
        missing+=("yt-dlp")
    fi
    
    if ! command -v ffmpeg &> /dev/null; then
        missing+=("ffmpeg")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_msg "$RED" "❌ Missing required dependencies: ${missing[*]}"
        print_msg "$YELLOW" "Install with: brew install ${missing[*]}"
        exit 1
    fi
}

# Extract video IDs from watch_videos URL
extract_from_url() {
    local url=$1
    # Extract the video_ids parameter
    if [[ "$url" == *"video_ids="* ]]; then
        local ids_part="${url#*video_ids=}"
        ids_part="${ids_part%%&*}"  # Remove anything after &
        IFS=',' read -ra extracted_ids <<< "$ids_part"
        VIDEO_IDS+=("${extracted_ids[@]}")
        print_msg "$GREEN" "✓ Extracted ${#extracted_ids[@]} video IDs from URL"
    else
        print_msg "$RED" "❌ Could not find video_ids in URL"
        exit 1
    fi
}

# Read video IDs from file
read_from_file() {
    local file=$1
    if [[ ! -f "$file" ]]; then
        print_msg "$RED" "❌ File not found: $file"
        exit 1
    fi
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        line=$(echo "$line" | tr -d '[:space:]')
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
            VIDEO_IDS+=("$line")
        fi
    done < "$file"
    
    print_msg "$GREEN" "✓ Read ${#VIDEO_IDS[@]} video IDs from file"
}

# Download audio for a single video
download_video() {
    local video_id=$1
    local index=$2
    local total=$3
    
    print_msg "$BLUE" "\n[$index/$total] Downloading: $video_id"
    
    local url="https://www.youtube.com/watch?v=$video_id"
    
    # yt-dlp options
    local output_template="${OUTPUT_DIR}/%(title)s.%(ext)s"
    
    # Sanitize OUTPUT_DIR to ensure it exists
    mkdir -p "$OUTPUT_DIR"
    
    if yt-dlp \
        --extract-audio \
        --audio-format "$FORMAT" \
        --audio-quality "$QUALITY" \
        --output "$output_template" \
        --no-playlist \
        --embed-thumbnail \
        --add-metadata \
        --progress \
        "$url" 2>&1; then
        print_msg "$GREEN" "✓ Downloaded successfully"
        return 0
    else
        print_msg "$RED" "✗ Failed to download $video_id"
        return 1
    fi
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                ;;
            --url|-u)
                shift
                extract_from_url "$1"
                shift
                ;;
            --file|-f)
                shift
                read_from_file "$1"
                shift
                ;;
            --output|-o)
                shift
                OUTPUT_DIR="$1"
                shift
                ;;
            --channel|-c)
                shift
                CHANNEL_NAME="$1"
                # Basic sanitization: remove slashes and other dangerous characters
                SAFE_CHANNEL=$(echo "$CHANNEL_NAME" | sed 's/[^a-zA-Z0-9._ -]//g' | sed 's/  */ /g')
                OUTPUT_DIR="${OUTPUT_DIR}/${SAFE_CHANNEL}"
                shift
                ;;
            --format|-F)
                shift
                FORMAT="$1"
                shift
                ;;
            --quality|-q)
                shift
                QUALITY="$1"
                shift
                ;;
            --)
                # End of options marker - remaining args are video IDs
                shift
                VIDEO_IDS+=("$@")
                break
                ;;
            -*)
                print_msg "$RED" "Unknown option: $1"
                show_help
                ;;
            *)
                # Assume it's a video ID
                VIDEO_IDS+=("$1")
                shift
                ;;
        esac
    done
}

# Main function
main() {
    parse_args "$@"
    
    # Check dependencies
    check_dependencies
    
    # Check if we have any video IDs
    if [ ${#VIDEO_IDS[@]} -eq 0 ]; then
        print_msg "$YELLOW" "No video IDs provided."
        print_msg "$YELLOW" "Usage: ./download-audio.sh [video_ids...] or --url 'playlist_url'"
        echo ""
        show_help
    fi
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Print summary
    echo ""
    print_msg "$BLUE" "═══════════════════════════════════════════"
    print_msg "$BLUE" "  YouTube Audio Downloader"
    print_msg "$BLUE" "═══════════════════════════════════════════"
    echo ""
    print_msg "$NC" "  Videos:  ${#VIDEO_IDS[@]}"
    print_msg "$NC" "  Format:  $FORMAT"
    print_msg "$NC" "  Output:  $OUTPUT_DIR"
    echo ""
    print_msg "$BLUE" "═══════════════════════════════════════════"
    
    # Download each video
    local success=0
    local failed=0
    local total=${#VIDEO_IDS[@]}
    
    for i in "${!VIDEO_IDS[@]}"; do
        local video_id="${VIDEO_IDS[$i]}"
        local index=$((i + 1))
        
        if download_video "$video_id" "$index" "$total"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    # Print summary
    echo ""
    print_msg "$BLUE" "═══════════════════════════════════════════"
    print_msg "$GREEN" "  ✓ Downloaded: $success"
    if [ $failed -gt 0 ]; then
        print_msg "$RED" "  ✗ Failed: $failed"
    fi
    print_msg "$NC" "  📁 Saved to: $OUTPUT_DIR"
    print_msg "$BLUE" "═══════════════════════════════════════════"
    
    # Open output folder if on macOS
    if [[ "$OSTYPE" == "darwin"* ]] && [ $success -gt 0 ]; then
        print_msg "$YELLOW" "\nPress Enter to open folder, or Ctrl+C to exit..."
        read -r
        open "$OUTPUT_DIR"
    fi
}

main "$@"
