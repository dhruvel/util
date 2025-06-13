#!/bin/bash

# ORB-SLAM2 Installation Script for Ubuntu 24.04 (Noble) with ROS2 Jazzy
# Improved version with proper version control and 4-core optimization
# This script installs ORB-SLAM2 and all its dependencies with specific versions
# Usage: curl -sSL https://your-server.com/install_orb_slam2.sh | bash
# Or: wget -O - https://your-server.com/install_orb_slam2.sh | bash

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version specifications for compatibility
OPENCV_VERSION="4.5.5"  # Known stable version with ORB-SLAM2
PANGOLIN_VERSION="v0.6"  # Stable version
ORB_SLAM2_COMMIT="52c2bb6"  # Last stable commit before major changes
EIGEN_VERSION="3.3.9"   # Compatible version

# Optimization for 4-core system
NUM_CORES=3  # Use 3 cores, leave 1 for system

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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup and restore on failure
backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$1.backup.$(date +%s)"
    fi
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
print_status "Using $NUM_CORES cores for compilation (optimized for 4-core system)"

# Set installation directory
INSTALL_DIR="$HOME/orb_slam2_ws"
print_status "Installation directory: $INSTALL_DIR"

# Create workspace directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

print_status "Updating package lists..."
sudo apt update

# Install essential build tools first
print_status "Installing essential build tools..."
sudo apt install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    curl \
    wget \
    unzip

print_status "Installing system dependencies..."
sudo apt install -y \
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
    libopencore-amrnb-dev \
    libopencore-amrwb-dev \
    libtheora-dev \
    libopus-dev \
    libfaac-dev \
    libmp3lame-dev \
    libgles2-mesa-dev \
    libglew-dev \
    yasm \
    libatlas-base-dev \
    libsuitesparse-dev

# Install ROS2 Jazzy if not already installed
if ! command_exists ros2; then
    print_status "Installing ROS2 Jazzy..."
    
    # Add ROS2 repository
    sudo apt install -y software-properties-common
    sudo add-apt-repository universe -y
    sudo apt update
    
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
    ros-jazzy-image-transport \
    ros-jazzy-tf2 \
    ros-jazzy-tf2-ros \
    ros-jazzy-tf2-geometry-msgs

# Initialize rosdep if not already done
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    print_status "Initializing rosdep..."
    sudo rosdep init
fi
rosdep update

# Install specific Eigen version
print_status "Installing Eigen3 version $EIGEN_VERSION..."
if [ ! -d "eigen-$EIGEN_VERSION" ]; then
    wget -O eigen.tar.gz https://gitlab.com/libeigen/eigen/-/archive/$EIGEN_VERSION/eigen-$EIGEN_VERSION.tar.gz
    tar -xzf eigen.tar.gz
    rm eigen.tar.gz
    
    cd eigen-$EIGEN_VERSION
    mkdir -p build
    cd build
    
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
    make -j$NUM_CORES
    sudo make install
    
    cd "$INSTALL_DIR"
else
    print_status "Eigen $EIGEN_VERSION already exists, skipping build..."
fi

# Install specific OpenCV version
print_status "Installing and building OpenCV $OPENCV_VERSION..."
if [ ! -d "opencv-$OPENCV_VERSION" ]; then
    wget -O opencv.zip https://github.com/opencv/opencv/archive/$OPENCV_VERSION.zip
    wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/$OPENCV_VERSION.zip
    unzip -q opencv.zip
    unzip -q opencv_contrib.zip
    rm opencv.zip opencv_contrib.zip
    
    cd opencv-$OPENCV_VERSION
    mkdir -p build
    cd build
    
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-$OPENCV_VERSION/modules \
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
        -D INSTALL_PYTHON_EXAMPLES=OFF \
        -D INSTALL_C_EXAMPLES=OFF \
        -D BUILD_opencv_python2=OFF \
        -D BUILD_opencv_python3=ON \
        -D OPENCV_GENERATE_PKGCONFIG=ON \
        ..
    
    make -j$NUM_CORES
    sudo make install
    sudo ldconfig
    
    cd "$INSTALL_DIR"
else
    print_status "OpenCV $OPENCV_VERSION already exists, skipping build..."
fi

# Install specific Pangolin version
print_status "Installing Pangolin $PANGOLIN_VERSION..."
if [ ! -d "Pangolin" ]; then
    git clone https://github.com/stevenlovegrove/Pangolin.git
    cd Pangolin
    git checkout $PANGOLIN_VERSION
    
    mkdir -p build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$NUM_CORES
    sudo make install
    sudo ldconfig
    
    cd "$INSTALL_DIR"
else
    print_status "Pangolin already exists, checking out correct version..."
    cd Pangolin
    git fetch
    git checkout $PANGOLIN_VERSION
    
    if [ ! -d "build" ]; then
        mkdir -p build
        cd build
        cmake .. -DCMAKE_BUILD_TYPE=Release
        make -j$NUM_CORES
        sudo make install
        sudo ldconfig
    fi
    
    cd "$INSTALL_DIR"
fi

# Clone and checkout specific ORB-SLAM2 version
print_status "Cloning ORB-SLAM2 and checking out stable commit..."
if [ ! -d "ORB_SLAM2" ]; then
    git clone https://github.com/raulmur/ORB_SLAM2.git
    cd ORB_SLAM2
    git checkout $ORB_SLAM2_COMMIT
    cd "$INSTALL_DIR"
else
    print_status "ORB-SLAM2 already exists, checking out stable commit..."
    cd ORB_SLAM2
    git fetch
    git checkout $ORB_SLAM2_COMMIT
    cd "$INSTALL_DIR"
fi

cd ORB_SLAM2

print_status "Building ORB-SLAM2..."

# Apply comprehensive compatibility fixes
print_status "Applying compatibility fixes for Ubuntu 24.04..."

# Backup original files
backup_file CMakeLists.txt
backup_file include/System.h

# Fix C++ standard - Ubuntu 24.04 needs C++14 minimum for ORB-SLAM2
sed -i 's/set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall  -O3 -march=native ")/set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -O3 -march=native -std=c++14")/g' CMakeLists.txt

# Add additional compiler flags for modern GCC
cat >> CMakeLists.txt << 'EOF'

# Additional flags for Ubuntu 24.04 compatibility
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations -Wno-unused-function -Wno-unused-variable")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-sign-compare -Wno-reorder -Wno-unused-but-set-variable")
EOF

# Fix usleep issue (deprecated in POSIX.1-2008)
if grep -q "usleep" include/System.h; then
    sed -i 's/#include <unistd.h>/#include <unistd.h>\n#include <thread>\n#include <chrono>/g' include/System.h
fi

if grep -q "usleep" src/System.cc; then
    sed -i 's/usleep(\([0-9]*\))/std::this_thread::sleep_for(std::chrono::microseconds(\1))/g' src/System.cc
fi

# Fix potential issues in Thirdparty libraries
print_status "Fixing Thirdparty libraries..."

# Fix DBoW2 CMakeLists.txt
if [ -f "Thirdparty/DBoW2/CMakeLists.txt" ]; then
    backup_file Thirdparty/DBoW2/CMakeLists.txt
    sed -i 's/set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall  -O3 -march=native ")/set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -O3 -march=native -std=c++14")/g' Thirdparty/DBoW2/CMakeLists.txt
fi

# Fix g2o CMakeLists.txt
if [ -f "Thirdparty/g2o/CMakeLists.txt" ]; then
    backup_file Thirdparty/g2o/CMakeLists.txt
    sed -i 's/SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -O3 -march=native ")/SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -O3 -march=native -std=c++14")/g' Thirdparty/g2o/CMakeLists.txt
fi

# Build DBoW2
print_status "Building DBoW2..."
cd Thirdparty/DBoW2
if [ -d "build" ]; then
    rm -rf build
fi
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$NUM_CORES
cd ../../..

# Build g2o
print_status "Building g2o..."
cd Thirdparty/g2o
if [ -d "build" ]; then
    rm -rf build
fi
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$NUM_CORES
cd ../../..

# Build ORB-SLAM2 main library
print_status "Building ORB-SLAM2 main library..."
if [ -d "build" ]; then
    rm -rf build
fi
mkdir -p build
cd build

cmake .. -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON

make -j$NUM_CORES

cd ..

# Verify build success
if [ ! -f "lib/libORB_SLAM2.so" ]; then
    print_error "ORB-SLAM2 library build failed!"
    exit 1
fi

print_success "ORB-SLAM2 core library built successfully!"

# Build examples
print_status "Building ORB-SLAM2 examples..."
cd Examples/RGB-D
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$NUM_CORES
cd ../../..

cd Examples/Stereo
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$NUM_CORES
cd ../../..

cd Examples/Monocular
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$NUM_CORES
cd ../../..

print_status "Building ROS2 wrapper..."
# Create ROS2 workspace for ORB-SLAM2
ROS2_WS="$INSTALL_DIR/orb_slam2_ros2_ws"
mkdir -p "$ROS2_WS/src"
cd "$ROS2_WS/src"

# Create improved ROS2 wrapper
if [ ! -d "orb_slam2_ros2" ]; then
    print_status "Creating ROS2 wrapper structure..."
    mkdir -p orb_slam2_ros2/{src,include/orb_slam2_ros2,launch,config}
    
    # Create package.xml with proper dependencies
    cat > orb_slam2_ros2/package.xml << 'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd" schematypens="http://www.w3.org/2001/XMLSchema"?>
<package format="3">
  <name>orb_slam2_ros2</name>
  <version>1.0.0</version>
  <description>ROS2 wrapper for ORB-SLAM2 SLAM system</description>
  <maintainer email="user@example.com">User</maintainer>
  <license>GPLv3</license>

  <buildtool_depend>ament_cmake</buildtool_depend>
  
  <depend>rclcpp</depend>
  <depend>sensor_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>std_msgs</depend>
  <depend>cv_bridge</depend>
  <depend>image_transport</depend>
  <depend>tf2</depend>
  <depend>tf2_ros</depend>
  <depend>tf2_geometry_msgs</depend>
  
  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
EOF

    # Create improved CMakeLists.txt
    cat > orb_slam2_ros2/CMakeLists.txt << EOF
cmake_minimum_required(VERSION 3.8)
project(orb_slam2_ros2)

# Set C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic -Wno-deprecated-declarations)
endif()

# Find packages
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)  
find_package(std_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(image_transport REQUIRED)
find_package(tf2 REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)

# Find OpenCV
find_package(OpenCV $OPENCV_VERSION REQUIRED)

# Find ORB-SLAM2
set(ORB_SLAM2_ROOT_DIR $INSTALL_DIR/ORB_SLAM2)
find_library(ORB_SLAM2_LIBRARY
    NAMES ORB_SLAM2
    PATHS \${ORB_SLAM2_ROOT_DIR}/lib
    REQUIRED
)

# Include directories
include_directories(
  include
  \${ORB_SLAM2_ROOT_DIR}
  \${ORB_SLAM2_ROOT_DIR}/include
  \${ORB_SLAM2_ROOT_DIR}/Thirdparty/DBoW2
  \${ORB_SLAM2_ROOT_DIR}/Thirdparty/g2o
)

# Create sample node (placeholder)
add_executable(orb_slam2_node src/orb_slam2_node.cpp)

ament_target_dependencies(orb_slam2_node
  rclcpp
  sensor_msgs
  geometry_msgs
  nav_msgs
  std_msgs
  cv_bridge
  image_transport
  tf2
  tf2_ros
  tf2_geometry_msgs
)

target_link_libraries(orb_slam2_node
  \${ORB_SLAM2_LIBRARY}
  \${OpenCV_LIBS}
  \${ORB_SLAM2_ROOT_DIR}/lib/libDBoW2.so
  \${ORB_SLAM2_ROOT_DIR}/lib/libg2o.so
)

# Install
install(TARGETS orb_slam2_node
  DESTINATION lib/\${PROJECT_NAME}
)

install(DIRECTORY launch config
  DESTINATION share/\${PROJECT_NAME}
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
EOF

    # Create placeholder ROS2 node
    cat > orb_slam2_ros2/src/orb_slam2_node.cpp << 'EOF'
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <cv_bridge/cv_bridge.h>

class OrbSlam2Node : public rclcpp::Node
{
public:
    OrbSlam2Node() : Node("orb_slam2_node")
    {
        RCLCPP_INFO(this->get_logger(), "ORB-SLAM2 ROS2 Node initialized");
        // TODO: Initialize ORB-SLAM2 system here
    }

private:
    // TODO: Add ORB-SLAM2 integration
};

int main(int argc, char** argv)
{
    rclcpp::init(argc, argv);
    auto node = std::make_shared<OrbSlam2Node>();
    rclcpp::spin(node);
    rclcpp::shutdown();
    return 0;
}
EOF
fi

# Build ROS2 workspace
cd "$ROS2_WS"
print_status "Building ROS2 workspace..."
source /opt/ros/jazzy/setup.bash

# Check dependencies first
rosdep install --from-paths src --ignore-src -r -y || true

colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release --parallel-workers $NUM_CORES

# Set up environment
print_status "Setting up environment..."
if ! grep -q "ORB-SLAM2 Environment" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# ORB-SLAM2 Environment" >> ~/.bashrc
    echo "export ORB_SLAM2_ROOT=$INSTALL_DIR/ORB_SLAM2" >> ~/.bashrc
    echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$ORB_SLAM2_ROOT/lib" >> ~/.bashrc
    echo "source $ROS2_WS/install/setup.bash" >> ~/.bashrc
fi

# Create comprehensive test script
cat > "$INSTALL_DIR/test_orb_slam2.sh" << EOF
#!/bin/bash
echo "Testing ORB-SLAM2 installation..."
echo "=================================="
echo "ORB-SLAM2 Root: \$ORB_SLAM2_ROOT"
echo "OpenCV Version: $OPENCV_VERSION"
echo "Pangolin Version: $PANGOLIN_VERSION"
echo "Eigen Version: $EIGEN_VERSION"
echo ""

echo "Checking core libraries..."
if [ -f "\$ORB_SLAM2_ROOT/lib/libORB_SLAM2.so" ]; then
    echo "✓ ORB-SLAM2 library found"
else
    echo "✗ ORB-SLAM2 library not found"
fi

if [ -f "\$ORB_SLAM2_ROOT/lib/libDBoW2.so" ]; then
    echo "✓ DBoW2 library found"
else
    echo "✗ DBoW2 library not found"
fi

if [ -f "\$ORB_SLAM2_ROOT/lib/libg2o.so" ]; then
    echo "✓ g2o library found"
else
    echo "✗ g2o library not found"
fi

echo ""
echo "Checking executables..."
for example_dir in RGB-D Stereo Monocular; do
    if [ -d "\$ORB_SLAM2_ROOT/Examples/\$example_dir" ]; then
        echo "✓ \$example_dir examples directory found"
    fi
done

echo ""
echo "Checking vocabulary file..."
if [ -f "\$ORB_SLAM2_ROOT/Vocabulary/ORBvoc.txt" ]; then
    echo "✓ ORB vocabulary file found"
else
    echo "✗ ORB vocabulary file not found"
fi

echo ""
echo "Testing OpenCV installation..."
pkg-config --modversion opencv4 && echo "✓ OpenCV pkg-config working" || echo "✗ OpenCV pkg-config issue"

echo ""
echo "ROS2 Integration Test..."
source /opt/ros/jazzy/setup.bash
source $ROS2_WS/install/setup.bash
if ros2 pkg list | grep -q orb_slam2_ros2; then
    echo "✓ ORB-SLAM2 ROS2 package found"
else
    echo "✗ ORB-SLAM2 ROS2 package not found"
fi
EOF

chmod +x "$INSTALL_DIR/test_orb_slam2.sh"

# Create usage examples
cat > "$INSTALL_DIR/run_examples.sh" << EOF
#!/bin/bash
# ORB-SLAM2 Example Runner
source ~/.bashrc

echo "ORB-SLAM2 Example Commands:"
echo "=========================="
echo ""
echo "1. RGB-D SLAM (TUM dataset):"
echo "   cd \$ORB_SLAM2_ROOT"
echo "   ./Examples/RGB-D/rgbd_tum Vocabulary/ORBvoc.txt Examples/RGB-D/TUM1.yaml PATH_TO_SEQUENCE_FOLDER ASSOCIATIONS_FILE"
echo ""
echo "2. Monocular SLAM (TUM dataset):"
echo "   cd \$ORB_SLAM2_ROOT"  
echo "   ./Examples/Monocular/mono_tum Vocabulary/ORBvoc.txt Examples/Monocular/TUM1.yaml PATH_TO_SEQUENCE_FOLDER"
echo ""
echo "3. Stereo SLAM (KITTI dataset):"
echo "   cd \$ORB_SLAM2_ROOT"
echo "   ./Examples/Stereo/stereo_kitti Vocabulary/ORBvoc.txt Examples/Stereo/KITTI00-02.yaml PATH_TO_DATASET_FOLDER/dataset/sequences/SEQUENCE_NUMBER"
echo ""
echo "Download datasets from:"
echo "- TUM: https://vision.in.tum.de/data/datasets/rgbd-dataset/download"
echo "- KITTI: http://www.cvlibs.net/datasets/kitti/eval_odometry.php"
EOF

chmod +x "$INSTALL_DIR/run_examples.sh"

print_success "ORB-SLAM2 installation completed successfully!"
print_status "=================================="
print_status "Installation Summary:"
print_status "- Installation directory: $INSTALL_DIR"
print_status "- OpenCV version: $OPENCV_VERSION"
print_status "- Pangolin version: $PANGOLIN_VERSION" 
print_status "- Eigen version: $EIGEN_VERSION"
print_status "- ORB-SLAM2 commit: $ORB_SLAM2_COMMIT"
print_status "- Optimized for 4-core system (using $NUM_CORES cores)"
print_status "=================================="

print_status "Next steps:"
echo "1. Restart your terminal or run: source ~/.bashrc"
echo "2. Test the installation: $INSTALL_DIR/test_orb_slam2.sh"
echo "3. See example commands: $INSTALL_DIR/run_examples.sh"
echo "4. Download a dataset and try running ORB-SLAM2"

print_status "ROS2 Integration:"
print_status "- ROS2 workspace: $ROS2_WS"
print_status "- Extend the wrapper in: $ROS2_WS/src/orb_slam2_ros2/"

print_success "Installation script completed successfully!"
print_status "All components built with proper version control and 4-core optimization!"
