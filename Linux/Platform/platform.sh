#!/bin/zsh

function check_arch() {
    os_name=$(uname -s | awk '{print tolower($0)}')
    arch_type=$(uname -m | awk '{print tolower($0)}')

    if [ "$os_name" = "linux" ]; then
        export elk_arch_type="$arch_type"
        export elk_os_name="$os_name"
        #echo "ELK architecture type: $elk_arch_type"
    else
        echo "The system is not Linux."
    fi
}

check_arch 