#!/usr/bin/env bash

# Pre-requisite for running Inspec test framework in Travis-CI

install_chef_inspec () {
    
    [ -f /usr/bin/inspec ] &>/dev/null || {
        pushd /tmp
        curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec   
        popd
        inspec version
        if [ $? -eq 0 ]
        then
          echo "Successfully Installed Inspec"
          exit 0
        else
          echo "Inspec Installation Failed" >&2
          exit 1
        fi
    }    

}

install_chef_inspec



