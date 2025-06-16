#!/bin/bash

# Install dependencies
sudo apt-get update
sudo apt-get install -y cmake gcc g++ python-dev python-numpy python3-dev python3-numpy libavcodec-dev libavformat-dev libswscale-dev libgstreamer-plugins-base1.0-dev libfstreamer1.0-dev libgtk2.0-dev libgtk-3-dev libpng-dev libjpeg-dev libopenexr-dev libtiff-dev libwebp-dev

# Build OpenCV
sudo apt-get install -y git
git clone https://github.com/opencv/opencv.git
cd opencv
mkdir build
cd build
cmake ../
make -j$(nproc)
sudo make install
cd

