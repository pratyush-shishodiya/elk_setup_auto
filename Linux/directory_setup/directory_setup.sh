#!/bin/bash

dir=("elasticsearch" "kibana" "logstash")
function check_create_dir(){
    #creating directories in /opt mount
    for i in "${dir[@]}"; do
        if [ -d "/opt/$i" ]; then
            sudo rm -rf "/opt/$i"
        fi
    done

}

check_create_dir