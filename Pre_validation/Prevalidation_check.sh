#!/bin/bash
script_path=$(readlink -f ../..)
echo $script_path
source "$script_path/ELK_Setup/Platform_info/platform.sh"

function check_java(){
    java -version
    if [ $? -ne 0 ]
    then
        echo "Java is not installed in the system. Please install the latest version of it"
        read -p "Do you want to install the Java-17: Yes or No" choice
        if [ $choice -eq "Yes" ] || [ $choice -eq "yes" ] || [ $choice -eq "y" ];
        then
            if [ $elk_os_name -eq "darwin" ];
            then
                brew install openjdk@17
                sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
                java -version
                if [ $? -eq 0 ];
                then
                    echo "Java had been installed succesfully"
                else
                    echo "Java had not installed succesfully, check logs for error......"
                    exit 1
                fi
            elif [ $elk_os_name -eq "linux" ];
            then
                sudo apt update
                sudo apt install openjdk-17-jdk -y
                java -version
                if [ $? -eq 0 ];
                then
                    echo "Java had been installed succesfully"
                else
                    echo "Java had not installed succesfully, check log for error ......."
                    exit 1
                fi
            else
                echo "Unknowd OS, can't install the java"
                exit 1
            fi
        else
            echo "Exting from the script......."
            exit 1
        fi
    elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 17.0.0 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
    then
        if [ $elk_os_name -eq "darwin" ];
        then
            brew install openjdk@17
            sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
            java -version
            if [ $? -eq 0 ];
            then
                echo "Java had been installed succesfully"
            else
                echo "Java had not installed succesfully, check logs for error......"
                exit 1
            fi
        elif [ $elk_os_name -eq "linux" ];
        then
            sudo apt update
            sudo apt install openjdk-17-jdk -y
            java -version
            if [ $? -eq 0 ];
            then
                echo "Java had been installed succesfully"
            else
                echo "Java had not installed succesfully, check log for error ......."
                exit 1
            fi
        else
            echo "Unknowd OS, can't install the java"
            exit 1
        fi


}

check_java
#Check wether the java is already present in the system or not
#If java is not present, then either the script or Downlad the compatible versiob of java
#Check wether any elasticsearch/Kibana/Logstash service is running or not
#if the service is running the stop it and delete all the service file of elasticsearch/Kibana/Logstash for cleanup
#check wether the /opt directory have enoguh space for ELK tech or not



# #!/bin/bash

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
#     echo "Checking for running ELK services..."
#     services=("elasticsearch" "kibana" "logstash")
    
#     for service in "${services[@]}"; do
#         if systemctl is-active --quiet $service 2>/dev/null; then
#             echo "Stopping $service service..."
#             sudo systemctl stop $service
#         fi
#     done
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

# # Main script execution
# check_java
# check_elk_services
# check_disk_space

# echo "ELK installation prerequisites checked successfully."