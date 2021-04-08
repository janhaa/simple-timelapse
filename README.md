# simple-timelapse

Call as `simple-timelapse.sh 1m` to take an image every 1 minute.

Use any format supported by (sleep)[https://man7.org/linux/man-pages/man1/sleep.1.html]

## code
```bash
cam="GENERAL WEBCAM"

mkdir images
cd images
for (( ; ; ))
do
    date=$(date +%s)
    ffmpeg -f dshow -i "video=$cam" -frames:v 30 "img-$date-%d.jpg"
    for i in {1..29}
    do
        rm -f "img-$date-$i.jpg"
    done
    sleep $1
done
cd ..
```
