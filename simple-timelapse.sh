#!/bin/bash

# Detect operating system and set camera input accordingly
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
    # Windows - use dshow
    cam="GENERAL WEBCAM"
    input_format="-f dshow -i video=$cam"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux - use video4linux2
    cam="/dev/video0"
    input_format="-f v4l2 -i $cam"
else
    echo "Unsupported operating system: $OSTYPE"
    exit 1
fi

mkdir -p images
cd images

for (( ; ; ))
do
    date=$(date +%s)
    ffmpeg $input_format -frames:v 30 "img-$date-%d.jpg"
    
    # Remove intermediate frames, keep only the last one (frame 30)
    for i in {1..29}
    do
        rm -f "img-$date-$i.jpg"
    done
    
    sleep $1
done

cd ..
