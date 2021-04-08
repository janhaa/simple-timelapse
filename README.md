# simple-timelapse

`simple-timelapse.sh 1m` takes an image every 1 minute.

```
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
