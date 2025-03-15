#!/bin/bash

source "/Users/pratyushshishodiya/Desktop/Github_shell scripts/ELK_Setup/ELK_download/Check_dir/check_and_create_dir.sh"

#version should be provided through prompt
function elastic_package(){
    
    cd /opt/Elasticsearch
    sudo wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-"$version"-"$os_name"-"$elk_arch_type".tar.gz
    sudo tar -xvzf elasticsearch-"$version"-"$os_name"-"$elk_arch_type".tar.gz

    sudo rm -rf elasticsearch-"$version"-"$os_name"-"$elk_arch_type".tar.gz
}

elastic_package
