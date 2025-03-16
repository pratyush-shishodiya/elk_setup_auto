#!/bin/bash

function check_arch() {
    os_name=$(uname -s | awk '{print tolower($0)}')
    arch_type=$(uname -m | awk '{print tolower($0)}')

    if [ "$os_name" = "linux" ]; then
        export elk_arch_type="$arch_type"
        export elk_os_name="$os_name"
        #echo "ELK architecture type: $elk_arch_type"
    elif [ "$os_name" = "darwin" ] && [ "$arch_type" = "arm64" ]; then
        export elk_arch_type="aarch64"
        export elk_os_name="$os_name"
        #echo "ELK architecture type: $elk_arch_type"
    else
        echo "The system is neither Linux nor Darwin."
    fi
}

check_arch  # Call the function

# If you want to source another script, ensure it exists
# source platform.sh  # Uncomment this if needed
