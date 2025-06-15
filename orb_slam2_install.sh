#!/bin/bash

# Exit on error
set -e

echo "Starting ORB-SLAM2 installation for Ubuntu 24.04 and ROS2 Jazzy..."

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install ROS2 Jazzy dependencies
echo "Installing ROS2 Jazzy dependencies..."
sudo apt install -y software-properties-common
sudo add-apt-repository universe
sudo apt update && sudo apt install -y curl
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt update

# Install ROS2 Jazzy
echo "Installing ROS2 Jazzy..."
sudo apt install -y ros-jazzy-desktop

# Install ORB-SLAM2 dependencies
echo "Installing ORB-SLAM2 dependencies..."
sudo apt install -y build-essential cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
sudo apt install -y libtbbmalloc2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libglew-dev libboost-all-dev libssl-dev libepoxy-dev
sudo apt install -y libgl1-mesa-dev libglu1-mesa-dev libxmu-dev libxi-dev
sudo apt install -y libxcb-render0-dev libxcb-render-util0-dev libxcb-xkb-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-shape0-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-xinerama0-dev

# Install Pangolin (visualization library)
echo "Installing Pangolin..."
cd ~
git clone https://github.com/stevenlovegrove/Pangolin.git
cd Pangolin
git checkout v0.8
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF -DBUILD_TOOLS=OFF ..
make -j$(nproc)
sudo make install

# Install Eigen3
echo "Installing Eigen3..."
sudo apt install -y libeigen3-dev

# Install ORB-SLAM2
echo "Installing ORB-SLAM2..."
cd ~
git clone https://github.com/raulmur/ORB_SLAM2.git
cd ORB_SLAM2
chmod +x build.sh
./build.sh

# Add environment variables
echo "Adding environment variables..."
echo "export ROS_DISTRO=jazzy" >> ~/.bashrc
echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
echo "export ROS_PACKAGE_PATH=\${ROS_PACKAGE_PATH}:~/ORB_SLAM2/Examples/ROS" >> ~/.bashrc

# Build ROS wrapper
echo "Building ROS wrapper..."
cd ~/ORB_SLAM2/Examples/ROS/ORB_SLAM2
mkdir build
cd build
cmake .. -DROS_BUILD_TYPE=Release
make -j$(nproc)

echo "Installation complete! Please source your .bashrc file:"
echo "source ~/.bashrc"