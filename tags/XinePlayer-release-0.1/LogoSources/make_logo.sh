#!/bin/sh
# This little script is what I use to convert the logo PNG into a
# MPEG2 video stream suitable for passing to xine. It requires
# Image Magick and the mpeg2enc toolchain to be installed.
# It's not very robust so don't try using this as a generic MPEG
# encoder :).

INPUT_FILE=xinelogo2.png
OUTPUT_FILE=logo.mpv

GEOMETRY=`identify -verbose $INPUT_FILE | grep Geometry: | sed -e 's/^.*: \([0-9]*\)x\([0-9]*\)/-w \1 -h \2/'`

convert $INPUT_FILE $INPUT_FILE.yuv
yuv4mpeg $GEOMETRY <$INPUT_FILE.yuv | mpeg2enc -f 3 -a 2 -q 1 -b 7500 -o $OUTPUT_FILE     
rm $INPUT_FILE.yuv
