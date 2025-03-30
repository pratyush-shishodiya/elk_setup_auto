#!/bin/bash

#!/bin/bash

# Cross-platform way to get script directory
get_script_path() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$( cd -P "$( dirname "$source" )" && pwd )"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$( cd -P "$( dirname "$source" )/../.." && pwd )"
}

script_path=$(get_script_path)
echo "Script path: $script_path"
source "$script_path/ELK_Setup/Platform_info/platform.sh"

function check_java() {
    # Check if Java is installed
    if ! java -version &>/dev/null; then
        echo "Java is not installed in the system."
        install_java
    else
        # Check Java version
        java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        # Handle both old (1.8.0) and new (17.0.0) version formats
        if [[ "$java_version" == 1.* ]]; then
            # Convert 1.8.0 format to 8.0.0 for comparison
            compare_version=$(echo $java_version | sed 's/1\.//')
        else
            compare_version=$java_version
        fi
        
        # Compare version
        if [[ "$(printf '%s\n' "17.0.0" "$compare_version" | sort -V | head -n1)" != "17.0.0" ]]; then
            echo "Java version $java_version is installed but version 17+ is required."
            install_java
        else
            echo "Java $java_version is installed and meets requirements."
        fi
    fi
}

function install_java() {
    read -p "Do you want to install Java 17? (y/n): " choice
    # Use tr instead of ${choice,,} for case conversion to work on older bash versions
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    case "$choice" in
        y|yes)
            install_java_by_os
            ;;
        *)
            echo "Exiting the script. Java 17+ is required for ELK."
            exit 1
            ;;
    esac
}

function install_java_by_os() {
    echo "Installing Java 17 for $elk_os_name..."
    
    case "$elk_os_name" in
        darwin)
            if ! command -v brew &>/dev/null; then
                echo "Homebrew is not installed. Please install Homebrew first."
                exit 1
            fi
            brew install openjdk@17 || { echo "Failed to install Java with Homebrew"; exit 1; }
            sudo ln -sfn "$(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-17.jdk || echo "Warning: Could not create symlink to Java JDK. You may need to set JAVA_HOME manually."
            ;;
        linux)
            # Check for package manager
            if command -v apt &>/dev/null; then
                sudo apt update || echo "Warning: apt update failed, continuing anyway..."
                sudo apt install openjdk-17-jdk -y || { echo "Failed to install Java with apt"; exit 1; }
            elif command -v dnf &>/dev/null; then
                sudo dnf install java-17-openjdk-devel -y || { echo "Failed to install Java with dnf"; exit 1; }
            elif command -v yum &>/dev/null; then
                sudo yum install java-17-openjdk-devel -y || { echo "Failed to install Java with yum"; exit 1; }
            else
                echo "Unsupported Linux distribution. Please install Java 17 manually."
                exit 1
            fi
            ;;
        *)
            echo "Unknown OS: $elk_os_name, cannot install Java."
            exit 1
            ;;
    esac
    
    # Verify installation
    if java -version &>/dev/null; then
        java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo "Java $java_version has been installed successfully."
    else
        echo "Java installation failed. Check logs for errors."
        exit 1
    fi
}

function check_elk_services() {
    echo "Checking for running ELK services..."
    services=("elasticsearch" "kibana" "logstash")
    
    if [[ $elk_os_name = "linux" ]]; then
        for service in "${services[@]}"; do
            if systemctl is-active --quiet $service 2>/dev/null; then
                echo "Stopping $service service..."
                sudo systemctl stop $service
                
                # Verify service stopped
                if systemctl is-active --quiet $service 2>/dev/null; then
                    echo "Warning: $service service did not stop properly."
                fi
            else
                echo "$service is not running"
            fi
        done
    elif [[ $elk_os_name = "darwin" ]]; then
        for service in "${services[@]}"; do
            # Using more specific pattern matching to avoid false positives
            if pids=$(pgrep -f "/$service/" 2>/dev/null) || pids=$(pgrep -f "/bin/$service" 2>/dev/null); then
                echo "Stopping $service processes..."
                
                # First try graceful termination with SIGTERM
                for pid in $pids; do
                    echo "Sending SIGTERM to process with PID: $pid"
                    kill $pid 2>/dev/null
                done
                
                # Give processes time to shut down gracefully
                sleep 5
                
                # Check for remaining processes and force kill them
                if remaining_pids=$(pgrep -f "/$service/" 2>/dev/null) || remaining_pids=$(pgrep -f "/bin/$service" 2>/dev/null); then
                    echo "Some $service processes still running, using SIGKILL..."
                    for pid in $remaining_pids; do
                        echo "Force killing process with PID: $pid"
                        kill -9 $pid 2>/dev/null
                    done
                    
                    # Final verification
                    sleep 2
                    if pgrep -f "/$service/" >/dev/null 2>&1 || pgrep -f "/bin/$service" >/dev/null 2>&1; then
                        echo "Warning: Some $service processes could not be terminated."
                    else
                        echo "All $service processes successfully terminated."
                    fi
                else
                    echo "All $service processes successfully terminated."
                fi
            else
                echo "$service is not running"
            fi
        done
    fi
}

function check_disk_space() {
    echo "Checking disk space for ELK installation..."
    # Require at least 10GB free space
    required_space=$((10 * 1024 * 1024)) # 10GB in KB
    
    if [[ $elk_os_name = "linux" ]]; then
        target_dir="/opt"
        available_space=$(df -k "$target_dir" | awk 'NR==2 {print $4}')
    elif [[ $elk_os_name = "darwin" ]]; then
        target_dir="/opt"
        # macOS df has different output format
        available_space=$(df -k "$target_dir" | awk 'NR==2 {print $4}')
    else
        echo "Unknown OS: $elk_os_name, cannot check disk space."
        return 1
    fi
    
    if [[ $available_space -lt $required_space ]]; then
        echo "Warning: Less than 10GB available in $target_dir directory."
        echo "Available: $(($available_space / 1024 / 1024))GB"
        echo "Required: 10GB"
        read -p "Continue anyway? (y/n): " space_choice
        # Use tr instead of ${space_choice,,} for case conversion
        space_choice=$(echo "$space_choice" | tr '[:upper:]' '[:lower:]')
        if [[ "$space_choice" != "y" && "$space_choice" != "yes" ]]; then
            echo "Exiting due to insufficient disk space."
            exit 1
        fi
    else
        echo "Sufficient disk space available: $(($available_space / 1024 / 1024))GB"
    fi
}

# Execute main functionality here if needed
# For example:
check_java
check_elk_services
check_disk_space































# script_path=$(readlink -f ../..)
# echo "Script path: $script_path"
# source "$script_path/ELK_Setup/Platform_info/platform.sh"

# function check_java() {
#     # Check if Java is installed
#     if ! java -version &>/dev/null; then
#         echo "Java is not installed in the system."
#         install_java
#     else
#         # Check Java version
#         java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
#         # Handle both old (1.8.0) and new (17.0.0) version formats
#         if [[ "$java_version" == 1.* ]]; then
#             # Convert 1.8.0 format to 8.0.0 for comparison
#             compare_version=$(echo $java_version | sed 's/1\.//')
#         else
#             compare_version=$java_version
#         fi
        
#         # Compare version
#         if [[ "$(printf '%s\n' "17.0.0" "$compare_version" | sort -V | head -n1)" != "17.0.0" ]]; then
#             echo "Java version $java_version is installed but version 17+ is required."
#             install_java
#         else
#             echo "Java $java_version is installed and meets requirements."
#         fi
#     fi
# }

# function install_java() {
#     read -p "Do you want to install Java 17? (y/n): " choice
#     case "${choice,,}" in
#         y|yes)
#             install_java_by_os
#             ;;
#         *)
#             echo "Exiting the script. Java 17+ is required for ELK."
#             exit 1
#             ;;
#     esac
# }

# function install_java_by_os() {
#     echo "Installing Java 17 for $elk_os_name..."
    
#     case "$elk_os_name" in
#         darwin)
#             brew install openjdk@17
#             sudo ln -sfn "$(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-17.jdk
#             ;;
#         linux)
#             # Check for package manager
#             if command -v apt &>/dev/null; then
#                 sudo apt update
#                 sudo apt install openjdk-17-jdk -y
#             elif command -v dnf &>/dev/null; then
#                 sudo dnf install java-17-openjdk-devel -y
#             elif command -v yum &>/dev/null; then
#                 sudo yum install java-17-openjdk-devel -y
#             else
#                 echo "Unsupported Linux distribution. Please install Java 17 manually."
#                 exit 1
#             fi
#             ;;
#         *)
#             echo "Unknown OS: $elk_os_name, cannot install Java."
#             exit 1
#             ;;
#     esac
    
#     # Verify installation
#     if java -version &>/dev/null; then
#         echo "Java has been installed successfully."
#     else
#         echo "Java installation failed. Check logs for errors."
#         exit 1
#     fi
# }

# function check_elk_services() {
#     if [[ $elk_os_name = "linux" ]]; then
#         echo "Checking for running ELK services..."
#         services=("elasticsearch" "kibana" "logstash")
        
#         for service in "${services[@]}"; do
#             if systemctl is-active --quiet $service 2>/dev/null; then
#                 echo "Stopping $service service..."
#                 sudo systemctl stop $service
#             fi
#         done
#     elif [[ $elk_os_name = "darwin" ]]; then
#         echo "Checking for running ELK services..."
#         services=("elasticsearch" "kibana" "logstash")
        
#         for service in "${services[@]}"; do
#             # Check if process is running using pgrep
#             if pgrep -f "$service" > /dev/null; then
#                 echo "Stopping $service processes..."
#                 # Get all PIDs and kill each process
#                 pids=$(pgrep -f "$service")
#                 for pid in $pids; do
#                     echo "Killing process with PID: $pid"
#                     kill $pid
#                 done
                
#                 # Verify they all stopped
#                 sleep 3
#                 if pgrep -f "$service" > /dev/null; then
#                     echo "Some processes still running, using kill -9..."
#                     remaining_pids=$(pgrep -f "$service")
#                     for pid in $remaining_pids; do
#                         echo "Force killing process with PID: $pid"
#                         kill -9 $pid
#                     done
#                 fi
#             else
#                 echo "$service is not running"
#             fi
#         done
#     fi
# }


# function check_disk_space() {
#     echo "Checking disk space in /opt directory..."
#     # Require at least 10GB free space
#     required_space=$((10 * 1024 * 1024)) # 10GB in KB
    
#     available_space=$(df -k /opt | awk 'NR==2 {print $4}')
    
#     if [[ $available_space -lt $required_space ]]; then
#         echo "Warning: Less than 10GB available in /opt directory."
#         echo "Available: $(($available_space / 1024 / 1024))GB"
#         echo "Required: 10GB"
#         read -p "Continue anyway? (y/n): " space_choice
#         if [[ "${space_choice,,}" != "y" && "${space_choice,,}" != "yes" ]]; then
#             echo "Exiting due to insufficient disk space."
#             exit 1
#         fi
#     else
#         echo "Sufficient disk space available: $(($available_space / 1024 / 1024))GB"
#     fi
# }









########################################################################################################


# function check_elk_services() {

#     if [[ $elk_os_name = "linux" ]];
#     then
#         echo "Checking for running ELK services..."
#         services=("elasticsearch" "kibana" "logstash")
        
#         for service in "${services[@]}"; do
#             if systemctl is-active --quiet $service 2>/dev/null; then
#                 echo "Stopping $service service..."
#                 sudo systemctl stop $service
#             fi
#         done
#     elif [[ $elk_os_name = "darwin" ]];
#     then
#         echo "Checking for running ELK services..."
#         services=("elasticsearch" "kibana" "logstash")
        



# }



# function check_elk_services() {
#     if [[ $elk_os_name = "linux" ]]; then
#         echo "Checking for running ELK services..."
#         services=("elasticsearch" "kibana" "logstash")
        
#         for service in "${services[@]}"; do
#             if systemctl is-active --quiet $service 2>/dev/null; then
#                 echo "Stopping $service service..."
#                 sudo systemctl stop $service
#             fi
#         done
#     elif [[ $elk_os_name = "darwin" ]]; then
#         echo "Checking for running ELK services..."
#         services=("elasticsearch" "kibana" "logstash")
        
#         done
#     fi
# }


# # Main script execution
# check_java
# check_elk_services
# check_disk_space

# echo "ELK installation prerequisites checked successfully."







# #!/bin/bash
# script_path=$(readlink -f ../..)
# echo $script_path
# source "$script_path/ELK_Setup/Platform_info/platform.sh"

# function check_java(){
#     java -version
#     if [ $? -ne 0 ]
#     then
#         echo "Java is not installed in the system. Please install the latest version of it"
#         read -p "Do you want to install the Java-17: Yes or No" choice
#         if [ $choice -eq "Yes" ] || [ $choice -eq "yes" ] || [ $choice -eq "y" ];
#         then
#             if [ $elk_os_name -eq "darwin" ];
#             then
#                 brew install openjdk@17
#                 sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
#                 java -version
#                 if [ $? -eq 0 ];
#                 then
#                     echo "Java had been installed succesfully"
#                 else
#                     echo "Java had not installed succesfully, check logs for error......"
#                     exit 1
#                 fi
#             elif [ $elk_os_name -eq "linux" ];
#             then
#                 sudo apt update
#                 sudo apt install openjdk-17-jdk -y
#                 java -version
#                 if [ $? -eq 0 ];
#                 then
#                     echo "Java had been installed succesfully"
#                 else
#                     echo "Java had not installed succesfully, check log for error ......."
#                     exit 1
#                 fi
#             else
#                 echo "Unknowd OS, can't install the java"
#                 exit 1
#             fi
#         else
#             echo "Exting from the script......."
#             exit 1
#         fi
#     elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 17.0.0 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
#     then
#         if [ $elk_os_name -eq "darwin" ];
#         then
#             brew install openjdk@17
#             sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
#             java -version
#             if [ $? -eq 0 ];
#             then
#                 echo "Java had been installed succesfully"
#             else
#                 echo "Java had not installed succesfully, check logs for error......"
#                 exit 1
#             fi
#         elif [ $elk_os_name -eq "linux" ];
#         then
#             sudo apt update
#             sudo apt install openjdk-17-jdk -y
#             java -version
#             if [ $? -eq 0 ];
#             then
#                 echo "Java had been installed succesfully"
#             else
#                 echo "Java had not installed succesfully, check log for error ......."
#                 exit 1
#             fi
#         else
#             echo "Unknowd OS, can't install the java"
#             exit 1
#         fi


# }
