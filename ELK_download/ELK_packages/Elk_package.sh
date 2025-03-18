#!/bin/bash

#set -e  # Exit immediately if a command exits with a non-zero status
#/Users/pratyushshishodiya/Desktop/Github_shell_scripts/ELK_Setup/ELK_download/ELK_packages/Elk_package.sh
root_path=$(readlink -f ../../..)
echo $root_path

# Source required scripts
source "$root_path/ELK_Setup/Platform_info/platform.sh"
source "$root_path/ELK_Setup/ELK_download/Check_dir/check_and_create_dir.sh"

# ELK packages list
packages=("elasticsearch" "kibana" "logstash")

# Prompt for ELK version
#read -p "What ELK package version do you want to download: " version
read "version?What ELK package version do you want to download: "



# Ensure platform variables are set
if [[ -z "$elk_os_name" || -z "$elk_arch_type" || -z "$version" ]]; then
    echo "Error: OS name or architecture type is not set. Check platform.sh"
    exit 1
fi

# Function to download and extract ELK packages
function elk_package() {
    for i in "${packages[@]}"; do
        echo "Processing $i..."

        # Create directory if it doesn't exist
        sudo mkdir -p /opt/"$i"

        # Define package URL
        package_url="https://artifacts.elastic.co/downloads/$i/$i-$version-$elk_os_name-$elk_arch_type.tar.gz"
        
        echo "Downloading: $package_url"

        # Download package
        if ! sudo wget -P /opt/"$i" "$package_url"; then
            echo "Error downloading $i. Check the version and network connection."
            exit 1
        fi

        # Extract package
        sudo tar -C /opt/"$i" -xvzf "/opt/$i/$i-$version-$elk_os_name-$elk_arch_type.tar.gz"

        # Clean up tar.gz file
        sudo rm -rf "/opt/$i/$i-$version-$elk_os_name-$elk_arch_type.tar.gz"

        echo "$i installed successfully in /opt/$i"
    done
}

# Run function
elk_package







# #!/bin/bash
# source "/Users/pratyushshishodiya/Desktop/Github_shell_scripts/ELK_Setup/Platform_info/platform.sh"
# source "/Users/pratyushshishodiya/Desktop/Github_shell_scripts/ELK_Setup/ELK_download/Check_dir/check_and_create_dir.sh"
# package=("elasticsearch" "kibana" "logstash")

# read -p "What ELK package version do you want to download: " version

# #version should be provided through prompt
# function elk_package(){
    
#     for i in "${package[@]}";
#     do
#         sudo wget -P /opt/"$i" https://artifacts.elastic.co/downloads/"$i"/"$i"-"$version"-"$elk_os_name"-"$elk_arch_type".tar.gz
#         sudo tar -C /opt/"$i"/ -xvzf /opt/"$i"/"$i"-"$version"-"$elk_os_name"-"$elk_arch_type".tar.gz

#         sudo rm -rf /opt/"$i"/"$i"-"$version"-"$elk_os_name"-"$elk_arch_type".tar.gz
#     done
# }

# elk_package


#########################################################
