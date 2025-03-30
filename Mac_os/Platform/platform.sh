#!/bin/zsh

function check_arch() {
    os_name=$(uname -s | awk '{print tolower($0)}')
    arch_type=$(uname -m | awk '{print tolower($0)}')

    if [ "$os_name" = "darwin" ] && [ "$arch_type" = "arm64" ]; then
        export elk_arch_type="aarch64"
        export elk_os_name="$os_name"
        #echo "ELK architecture type: $elk_arch_type"
    else
        echo "The system is not Darwin."
    fi
}

check_arch 