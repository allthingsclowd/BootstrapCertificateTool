#!/usr/bin/env bash

setup_environment () {

    set -x
    # Install Prerequisites
    sudo apt-get update -y
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y universe
    sudo add-apt-repository -y ppa:certbot/certbot
    sudo apt-get update -y

    sudo apt-get install -y certbot

}

request_cert () {
    
    # Configure Domain Name
    DOMAIN=hashistack.ie

    certbot certonly --manual \
                    -d *.$DOMAIN -d $DOMAIN \
                    --agree-tos \
                    --manual-public-ip-logging-ok \
                    --preferred-challenges dns-01 \
                    --server https://acme-v02.api.letsencrypt.org/directory \
                    --register-unsafely-without-email \
                    --rsa-key-size 4096 \
                    --keep-until-expiring

}

setup_environment