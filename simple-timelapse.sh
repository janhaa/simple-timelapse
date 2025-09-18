#!/bin/bash

# Function to get the highest resolution for Linux
get_highest_resolution_linux() {
    local cam=$1
    # Get all supported formats and resolutions, extract the highest resolution
    v4l2-ctl --device="$cam" --list-formats-ext | \
    grep -o "Size: Discrete [0-9]*x[0-9]*" | \
    sed 's/Size: Discrete //' | \
    sort -t'x' -k1 -nr -k2 -nr | \
    head -1
}

# Function to get pixel format preference
get_best_pixel_format() {
    local cam=$1
    # Check available formats and prefer MJPG, then YUYV
    local formats=$(v4l2-ctl --device="$cam" --list-formats-ext)
    if echo "$formats" | grep -q "'MJPG'"; then
        echo "mjpeg"
    elif echo "$formats" | grep -q "'YUYV'"; then
        echo "yuyv422"
    else
        echo ""
    fi
}

# Detect operating system and set camera input accordingly
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
    # Windows - use dshow
    cam="GENERAL WEBCAM"
    # For Windows, we'll try to use a high resolution - adjust as needed
    input_format="-f dshow -video_size 1920x1080 -framerate 30 -i video=\"$cam\""
    echo "Windows detected - using DirectShow with 1920x1080 resolution"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux - use video4linux2
    cam="/dev/video0"
    
    # Check if v4l2-ctl is available
    if ! command -v v4l2-ctl &> /dev/null; then
        echo "v4l2-ctl not found. Installing v4l-utils..."
        sudo apt-get update && sudo apt-get install -y v4l-utils
    fi
    
    # Check if camera exists
    if [ ! -e "$cam" ]; then
        echo "Camera device $cam not found!"
        # Try to find available video devices
        echo "Available video devices:"
        ls /dev/video* 2>/dev/null || echo "No video devices found"
        exit 1
    fi
    
    # Get the highest resolution and best pixel format
    resolution=$(get_highest_resolution_linux "$cam")
    pixel_format=$(get_best_pixel_format "$cam")
    
    if [ -z "$resolution" ]; then
        echo "Could not determine camera resolution, using default"
        input_format="-f v4l2 -i $cam"
    else
        echo "Using highest resolution: $resolution"
        if [ -n "$pixel_format" ]; then
            echo "Using pixel format: $pixel_format"
            input_format="-f v4l2 -video_size $resolution -pixel_format $pixel_format -i $cam"
        else
            echo "Using default pixel format"
            input_format="-f v4l2 -video_size $resolution -i $cam"
        fi
    fi
    
    # Display camera capabilities
    echo "Camera capabilities:"
    v4l2-ctl --device="$cam" --list-formats-ext | head -20
else
    echo "Unsupported operating system: $OSTYPE"
    exit 1
fi

# Check if interval argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <interval_in_seconds>"
    echo "Example: $0 10  (captures every 10 seconds)"
    exit 1
fi

interval=$1
echo "Starting timelapse with $interval second intervals"

mkdir -p images
cd images

# Counter for image numbering
counter=1

echo "Press Ctrl+C to stop the timelapse"

for (( ; ; ))
do
    timestamp=$(date +%Y%m%d_%H%M%S)
    filename="timelapse_${counter}_${timestamp}.jpg"
    
    echo "Capturing frame $counter at $(date)"
    
    # Capture with high quality settings
    ffmpeg -y $input_format -frames:v 1 -q:v 2 "$filename" -loglevel warning
    
    if [ $? -eq 0 ]; then
        echo "Successfully captured: $filename"
        ((counter++))
    else
        echo "Failed to capture frame $counter"
    fi
    
    sleep $interval
done

cd ..
