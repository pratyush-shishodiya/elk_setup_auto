#!/bin/zsh

# Cross-platform way to get script directory in zsh
get_script_path() {
    local source="${(%):-%x}"
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
    read "choice?Do you want to install Java 17? (y/n): "
    # Lowercase conversion in zsh
    choice=${choice:l}
    case "$choice" in
        y|yes)
            install_java_for_macos
            ;;
        *)
            echo "Exiting the script. Java 17+ is required for ELK."
            exit 1
            ;;
    esac
}

function install_java_for_macos() {
    echo "Installing Java 17 for macOS..."
    
    if ! command -v brew &>/dev/null; then
        echo "Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi
    
    brew install openjdk@17 || { echo "Failed to install Java with Homebrew"; exit 1; }
    
    # Create symlink to Java JDK
    sudo ln -sfn "$(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-17.jdk || echo "Warning: Could not create symlink to Java JDK. You may need to set JAVA_HOME manually."
    
    # Set up JAVA_HOME in zsh profile if not already set
    grep -q "export JAVA_HOME=" ~/.zshrc || echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17)' >> ~/.zshrc
    
    # Verify installation
    if java -version &>/dev/null; then
        java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo "Java $java_version has been installed successfully."
        echo "You may need to restart your terminal or run 'source ~/.zshrc' to use the new Java version."
    else
        echo "Java installation failed. Check logs for errors."
        exit 1
    fi
}

function check_elk_services() {
    echo "Checking for running ELK services on macOS..."
    services=("elasticsearch" "kibana" "logstash")
    
    for service in $services; do
        # macOS-specific process checking
        if pgrep -x "$service" &>/dev/null || pgrep -f "$service" &>/dev/null; then
            echo "Found running $service processes..."
            
            # Using pkill for macOS - first with normal signal
            echo "Attempting to stop $service processes gracefully..."
            pkill -f "$service" 2>/dev/null
            
            # Give processes time to shut down
            sleep 5
            
            # Check if processes are still running
            if pgrep -f "$service" &>/dev/null; then
                echo "Some $service processes still running, using force kill..."
                pkill -9 -f "$service" 2>/dev/null
                
                # Final check
                sleep 2
                if pgrep -f "$service" &>/dev/null; then
                    echo "Warning: Some $service processes could not be terminated."
                    echo "Running processes:"
                    ps aux | grep -v grep | grep "$service"
                    echo "You may need to manually kill these processes or restart your system."
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
}

function check_disk_space() {
    echo "Checking disk space for ELK installation on macOS..."
    # Require at least 10GB free space
    required_space=$((10 * 1024 * 1024)) # 10GB in KB
    
    target_dir="/opt"
    # macOS specific df formatting
    available_space=$(df -k "$target_dir" | awk 'NR==2 {print $4}')
    
    if [[ $available_space -lt $required_space ]]; then
        echo "Warning: Less than 10GB available in $target_dir directory."
        echo "Available: $(($available_space / 1024 / 1024))GB"
        echo "Required: 10GB"
        read "space_choice?Continue anyway? (y/n): "
        # zsh lowercase conversion
        space_choice=${space_choice:l}
        if [[ "$space_choice" != "y" && "$space_choice" != "yes" ]]; then
            echo "Exiting due to insufficient disk space."
            exit 1
        fi
    else
        echo "Sufficient disk space available: $(($available_space / 1024 / 1024))GB"
    fi
}

function create_opt_if_needed() {
    # Check if /opt directory exists and create it if needed (common requirement on macOS)
    if [[ ! -d "/opt" ]]; then
        echo "/opt directory doesn't exist, creating it..."
        sudo mkdir -p /opt
        sudo chown $(whoami):admin /opt
        echo "Created /opt directory with correct permissions."
    fi
}

# Main execution
echo "Running ELK setup validation for macOS..."
create_opt_if_needed
check_java
check_elk_services
check_disk_space
echo "Validation complete."