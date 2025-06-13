#!/bin/bash

# ORB-SLAM2 Installation Script for Ubuntu 24.04 (Noble) with ROS2 Jazzy
# This script installs ORB-SLAM2 and all its dependencies
# Usage: curl -sSL https://your-server.com/install_orb_slam2.sh | bash
# Or: wget -O - https://your-server.com/install_orb_slam2.sh | bash

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons."
   print_status "Please run as a regular user with sudo privileges."
   exit 1
fi

# Check Ubuntu version
if ! grep -q "24.04" /etc/os-release; then
    print_warning "This script is designed for Ubuntu 24.04 (Noble). Your system might not be compatible."
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_status "Starting ORB-SLAM2 installation for Ubuntu 24.04 with ROS2 Jazzy..."

# Set installation directory
INSTALL_DIR="$HOME/orb_slam2_ws"
print_status "Installation directory: $INSTALL_DIR"

# Create workspace directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

print_status "Updating package lists..."
sudo apt update

print_status "Installing system dependencies..."
sudo apt install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    libjpeg-dev \
    libtiff5-dev \
    libpng-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libgtk-3-dev \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    python3-dev \
    python3-numpy \
    libtbb12-dev \
    libtbb-dev \
    libdc1394-dev \
    libxine2-dev \
    libv4l-dev \
    v4l-utils \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libavresample-dev \
    libvorbis-dev \
    libxvidcore-dev \
    libx264-dev \
    libgtk-3-dev \
    libopencore-amrnb-dev \
    libopencore-amrwb-dev \
    libtheora-dev \
    libvorbis-dev \
    libxvidcore-dev \
    libx264-dev \
    yasm \
    libfaac-dev \
    libmp3lame-dev \
    libopus-dev \
    libgles2-mesa-dev \
    libglew-dev \
    wget \
    unzip

# Install ROS2 Jazzy if not already installed
if ! command -v ros2 &> /dev/null; then
    print_status "Installing ROS2 Jazzy..."
    
    # Add ROS2 repository
    sudo apt install -y software-properties-common
    sudo add-apt-repository universe -y
    sudo apt update
    
    # Install curl if not present
    sudo apt install -y curl
    
    # Add ROS2 GPG key
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    
    # Add ROS2 repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
    
    sudo apt update
    sudo apt install -y ros-jazzy-desktop python3-argcomplete
    
    # Source ROS2
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
    source /opt/ros/jazzy/setup.bash
else
    print_status "ROS2 already installed, sourcing environment..."
    source /opt/ros/jazzy/setup.bash
fi

# Install additional ROS2 packages
print_status "Installing ROS2 development tools..."
sudo apt install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    ros-jazzy-cv-bridge \
    ros-jazzy-image-transport

# Initialize rosdep if not already done
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    print_status "Initializing rosdep..."
    sudo rosdep init
fi
rosdep update

print_status "Installing Eigen3..."
sudo apt install -y libeigen3-dev

print_status "Installing and building OpenCV 4.8.1..."
if [ ! -d "opencv-4.8.1" ]; then
    wget -O opencv.zip https://github.com/opencv/opencv/archive/4.8.1.zip
    wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.8.1.zip
    unzip opencv.zip
    unzip opencv_contrib.zip
    rm opencv.zip opencv_contrib.zip
    
    cd opencv-4.8.1
    mkdir -p build
    cd build
    
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-4.8.1/modules \
        -D WITH_TBB=ON \
        -D WITH_V4L=ON \
        -D WITH_QT=OFF \
        -D WITH_OPENGL=ON \
        -D WITH_GSTREAMER=ON \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_TESTS=OFF \
        -D BUILD_PERF_TESTS=OFF \
        -D PYTHON_DEFAULT_EXECUTABLE=/usr/bin/python3 \
        -D OPENCV_ENABLE_NONFREE=ON \
        ..
    
    make -j$(nproc)
    sudo make install
    sudo ldconfig
    
    cd "$INSTALL_DIR"
else
    print_status "OpenCV already exists, skipping build..."
fi

print_status "Installing Pangolin..."
if [ ! -d "Pangolin" ]; then
    git clone https://github.com/stevenlovegrove/Pangolin.git
    cd Pangolin
    mkdir -p build
    cd build
    cmake ..
    make -j$(nproc)
    sudo make install
    cd "$INSTALL_DIR"
else
    print_status "Pangolin already exists, skipping build..."
fi

print_status "Cloning ORB-SLAM2..."
if [ ! -d "ORB_SLAM2" ]; then
    git clone https://github.com/raulmur/ORB_SLAM2.git
else
    print_status "ORB_SLAM2 already exists, pulling latest changes..."
    cd ORB_SLAM2
    git pull
    cd "$INSTALL_DIR"
fi

cd ORB_SLAM2

print_status "Building ORB-SLAM2..."

# Fix potential compilation issues
print_status "Applying compatibility fixes..."

# Fix C++11/14 compatibility issues - Ubuntu 24.04 needs C++17 or higher
sed -i 's/set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall  -O3 -march=native ")/set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall  -O3 -march=native -std=c++17")/g' CMakeLists.txt

# Fix usleep issue (usleep is deprecated)
if grep -q "usleep" include/System.h; then
    sed -i 's/#include <unistd.h>/#include <unistd.h>\n#include <thread>\n#include <chrono>/g' include/System.h
    sed -i 's/usleep(\([0-9]*\))/std::this_thread::sleep_for(std::chrono::microseconds(\1))/g' src/System.cc
fi

# Fix potential issues with newer GCC versions
if [ -f "CMakeLists.txt" ]; then
    # Add required flags for modern GCC
    sed -i '/set(CMAKE_CXX_FLAGS/a set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations -Wno-unused-function")' CMakeLists.txt
fi

# Build DBoW2
print_status "Building DBoW2..."
cd Thirdparty/DBoW2
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
cd ../../..

# Build g2o
print_status "Building g2o..."
cd Thirdparty/g2o
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
cd ../../..

# Build ORB-SLAM2
print_status "Building ORB-SLAM2 main library..."
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

cd ..

print_status "Building ROS2 wrapper..."
# Create ROS2 workspace for ORB-SLAM2
mkdir -p "$INSTALL_DIR/orb_slam2_ros2_ws/src"
cd "$INSTALL_DIR/orb_slam2_ros2_ws/src"

# Clone or create a simple ROS2 wrapper (you might need to adapt this)
if [ ! -d "orb_slam2_ros2" ]; then
    print_status "Creating basic ROS2 wrapper structure..."
    mkdir -p orb_slam2_ros2/src
    mkdir -p orb_slam2_ros2/include
    mkdir -p orb_slam2_ros2/launch
    
    # Create basic package.xml
    cat > orb_slam2_ros2/package.xml << 'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd" schematypens="http://www.w3.org/2001/XMLSchema"?>
<package format="3">
  <name>orb_slam2_ros2</name>
  <version>1.0.0</version>
  <description>ROS2 wrapper for ORB-SLAM2</description>
  <maintainer email="user@example.com">User</maintainer>
  <license>GPLv3</license>

  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>sensor_msgs</depend>
  <depend>cv_bridge</depend>
  <depend>image_transport</depend>
  
  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
EOF

    # Create basic CMakeLists.txt
    cat > orb_slam2_ros2/CMakeLists.txt << EOF
cmake_minimum_required(VERSION 3.8)
project(orb_slam2_ros2)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(image_transport REQUIRED)

# Find ORB-SLAM2
set(ORB_SLAM2_ROOT_DIR $INSTALL_DIR/ORB_SLAM2)
find_library(ORB_SLAM2_LIBRARY
    NAMES ORB_SLAM2
    PATHS \${ORB_SLAM2_ROOT_DIR}/lib
)

include_directories(
  \${ORB_SLAM2_ROOT_DIR}
  \${ORB_SLAM2_ROOT_DIR}/include
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
EOF
fi

# Build ROS2 workspace
cd "$INSTALL_DIR/orb_slam2_ros2_ws"
print_status "Building ROS2 workspace..."
source /opt/ros/jazzy/setup.bash
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

# Set up environment
print_status "Setting up environment..."
echo "" >> ~/.bashrc
echo "# ORB-SLAM2 Environment" >> ~/.bashrc
echo "export ORB_SLAM2_ROOT=$INSTALL_DIR/ORB_SLAM2" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$ORB_SLAM2_ROOT/lib" >> ~/.bashrc
echo "source $INSTALL_DIR/orb_slam2_ros2_ws/install/setup.bash" >> ~/.bashrc

# Create a simple test script
cat > "$INSTALL_DIR/test_orb_slam2.sh" << 'EOF'
#!/bin/bash
echo "Testing ORB-SLAM2 installation..."
echo "ORB-SLAM2 Root: $ORB_SLAM2_ROOT"
echo "Checking if ORB-SLAM2 library exists..."
if [ -f "$ORB_SLAM2_ROOT/lib/libORB_SLAM2.so" ]; then
    echo "✓ ORB-SLAM2 library found"
else
    echo "✗ ORB-SLAM2 library not found"
fi

echo "Checking executables..."
for exe in mono_tum stereo_tum rgbd_tum mono_kitti stereo_kitti; do
    if [ -f "$ORB_SLAM2_ROOT/Examples/Monocular/$exe" ] || [ -f "$ORB_SLAM2_ROOT/Examples/Stereo/$exe" ] || [ -f "$ORB_SLAM2_ROOT/Examples/RGB-D/$exe" ]; then
        echo "✓ $exe found"
    fi
done
EOF

chmod +x "$INSTALL_DIR/test_orb_slam2.sh"

print_success "ORB-SLAM2 installation completed!"
print_status "Installation directory: $INSTALL_DIR"
print_status "Please restart your terminal or run: source ~/.bashrc"
print_status "Test the installation by running: $INSTALL_DIR/test_orb_slam2.sh"

print_status "Quick start guide:"
echo "1. Download a dataset (e.g., TUM RGB-D dataset)"
echo "2. Run ORB-SLAM2 with:"
echo "   cd $INSTALL_DIR/ORB_SLAM2"
echo "   ./Examples/RGB-D/rgbd_tum Vocabulary/ORBvoc.txt Examples/RGB-D/TUM1.yaml PATH_TO_SEQUENCE_FOLDER ASSOCIATIONS_FILE"

print_status "For ROS2 integration, you can extend the wrapper in:"
print_status "$INSTALL_DIR/orb_slam2_ros2_ws/src/orb_slam2_ros2/"

print_success "Installation script completed successfully!"
