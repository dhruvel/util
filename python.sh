# Declare an array of string with libraries to be installed
declare -a libraries=("numpy" "scapy" "nmap" "requests" "pycrypto" "pandas" "matplotlib" "scipy" "sklearn" "seaborn" "jupyter" "jupyterlab" "tensorflow" "keras" "opencv-python" "pillow" "h5py" "requests" "beautifulsoup4" "pyyaml" "flask" "django" "pyqt5" "pyqtgraph" "pyopengl" "pyopengl-accelerate" "pyqtwebengine" "pyqtchart" "pyqtsensors" "pyqtdatavisualization" "pyqtmultimedia" "pyqtxmlpatterns" "pyqtxml" "pyqtnetwork" "pyqtsql" "pyqtuitools" "pyqtopengl" "pyqtopengl" "pyqtsvg" "pyqtx11ex")

# Iterate the string array using for loop
for library in ${libraries[@]}; do
    echo "Installing $library"
    pip install $library
done
