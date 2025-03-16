#!/bin/bash

dir=("elasticsearch" "kibana" "logstash")
function check_create_dir(){
    for i in "${dir[@]}"; do
        if [ -d "/opt/$i" ]; then
            sudo rm -rf "/opt/$i"
            sudo mkdir "/opt/$i"
        else
            sudo mkdir "/opt/$i"
        fi
    done

}

check_create_dir