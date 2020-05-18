#!/usr/bin/env bash

setup_environment () {

    set +x
    # Install Prerequisites if necessary
    which certbot &>/dev/null || {
        echo -e "\nStart Let's Encrypt Certbot Installation\n"
        sudo apt-get update -y
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository -y universe
        sudo add-apt-repository -y ppa:certbot/certbot
        sudo apt-get update -y

        sudo apt-get install -y certbot
        certbot --version

        echo -e "\nCertbot Installation Complete\n"
    }


}

request_cert () {

    echo -e "Starting public certificate retrevial provess\n"
    # Configure Domain Name
    DOMAIN=hashistack.ie

    echo -e "Check if there's an existing Public Certificate that can be renewed\n"
    # Check if certs already exist
    if [ -f /usr/local/bootstrap/PublicCerts_Protect/etc/letsencrypt/live/hashistack.ie/fullchain.pem ]
    then
        echo -e "Existing certs found \nMoving cert directories back into place for renewal process\n"
        # Copy certs from host back into vm lets encrypt directory
        sudo cp -ar /usr/local/bootstrap/PublicCerts_Protect/etc/letsencrypt /etc/

        # Invoke the renewal process
        sudo certbot renew

        echo -e "Moving cert directories back onto host machine\n"
        # Copy the new certificate back off the VM to the host (rsync directory on vagrant)
        sudo cp -ar /etc/letsencrypt /usr/local/bootstrap/PublicCerts_Protect/etc/

        echo -e "Certificate renewal process finished\n"
        

    else

        echo -e "Manual Let's Encrypt Process starting...\n"

        # This will be an interactive manual process - you'll need access to you domain manager UI
        sudo certbot certonly --manual \
                -d *.$DOMAIN -d $DOMAIN \
                --agree-tos \
                --manual-public-ip-logging-ok \
                --preferred-challenges dns-01 \
                --server https://acme-v02.api.letsencrypt.org/directory \
                --register-unsafely-without-email \
                --rsa-key-size 4096 \
                --keep-until-expiring

        echo -e "Moving cert directories back onto host machine\n"
        # Copy the new certificate back off the VM to the host (rsync directory on vagrant)
        sudo cp -ar /etc/letsencrypt /usr/local/bootstrap/PublicCerts_Protect/etc/

        echo -e "Certificate creation process finished\n"
    fi    

}

setup_environment
request_cert