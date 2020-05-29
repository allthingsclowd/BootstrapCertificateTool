#!/usr/bin/env bash

setup_env () {

    set +x

    # Binary versions to check for
    [ -f /usr/local/bootstrap/var.env ] && {
        cat /usr/local/bootstrap/var.env
        source /usr/local/bootstrap/var.env
    }

    # Configure Directories
    export conf_dir=/usr/local/bootstrap/conf/certificates
    [ ! -d $conf_dir ] && mkdir -p $conf_dir
    export CA_dir=/usr/local/bootstrap/.bootstrap/Outputs/RootCA
    [ ! -d $CA_dir ] && mkdir -p $CA_dir
    export Int_CA_dir=/usr/local/bootstrap/.bootstrap/Outputs/IntermediateCAs
    [ ! -d $Int_CA_dir ] && mkdir -p $Int_CA_dir
    export Certs_dir=/usr/local/bootstrap/.bootstrap/Outputs/Certificates
    [ ! -d $Certs_dir ] && mkdir -p $Certs_dir 
    
    export CA=$CA_dir/hashistack-root-ca.pem
    export CA_KEY=$CA_dir/hashistack-root-ca-key.pem
    export Cert_Profiles=$conf_dir/certificate-profiles.json

  
    IFACE=`route -n | awk '$1 == "192.168.9.0" {print $8;exit}'`
    CIDR=`ip addr show ${IFACE} | awk '$2 ~ "192.168.9" {print $2}'`
    IP=${CIDR%%/24}
    
    if [ "${TRAVIS}" == "true" ]; then
        ROOTCERTPATH=tmp
        IP=${IP:-127.0.0.1}
        LEADER_IP=${IP}
    else
        ROOTCERTPATH=etc
    fi

    export ROOTCERTPATH

    CERTPASSCODE="${CERTPASSCODE:-bananas}"

}

generate_user_certificates () {

    echo -e "\n===================================================="
    echo -e "Check to see if SSH CLIENT CA for ${1} already exists?"
    # Generate a new OpenSSH CA if one does not already exist
    [ ! -f $Int_CA_dir/${1}/${1}-client-ca ] && \
        ssh-keygen -t rsa -N '' -C HASHISTACK-${1}-CLIENT-CA -b 4096 -f $Int_CA_dir/${1}/${1}-client-ca && \
        echo -e "\nNew SSH CLIENT CA created - $Int_CA_dir/${1}/${1}-client-ca" || \
        echo -e "\nSSH CLIENT CA found - $Int_CA_dir/${1}/${1}-client-ca - this will be re-used."
    
    echo -e "\nNow copy ${1}_client_ca.pub to the target host servers (NOT the client servers) e.g. /etc/ssh/${1}-client-ca.pub"
    echo -e "\nConfigure the target system to accept the client-ca signed keys when ssh is used"
    echo -e "\ne.g. grep -qxF 'TrustedUserCAKeys /etc/ssh/${1}-client-ca.pub' /etc/ssh/sshd_config || echo 'TrustedUserCAKeys /etc/ssh/${1}-client-ca.pub' | sudo tee -a /etc/ssh/sshd_config\n"
    echo -e "\nNow create the user keys and certificates -  \n"
    echo -e "\nNow sign the users (client) public ssh key, /home/someuser/.ssh/id_rsa.pub, as follows: Example ssh-keygen -s $Int_CA_dir/${1}/${1}-client-ca -I graham-dev -n root,vagrant,graham,pi -V -5:+52w -z 1 ~/.ssh/id_rsa.pub"
    echo -e "SSH Client CA process for ${1} has completed."

}

generate_host_certificates () {
    
    echo -e "\n===================================================="
    echo -e "Check to see if SSH CA for ${1} already exists?"
    # Generate a new OpenSSH CA if one does not already exist
    [ ! -f $Int_CA_dir/${1}/${1}-host-ca ] && \
        ssh-keygen -t rsa -N '' -C HASHISTACK-${1}-HOST-CA -b 4096 -f $Int_CA_dir/${1}/${1}-host-ca && \
        echo -e "\nNew SSH CA created - $Int_CA_dir/${1}/${1}-host-ca" || \
        echo -e "\nSSH CA found - $Int_CA_dir/${1}/${1}-host-ca - this will be re-used."
    
    # Create new host keys if they don't already exist
    echo -e "Generate new ssh keys for ${1} HOST Key CERTIFICATES"
    pushd $Certs_dir
    # Generate new keys if required
    [ ! -f $Certs_dir/${1}_host_rsa_key ] && \
        ssh-keygen -N '' -C HASHISTACK-${1}-HOST-KEY -t rsa -b 4096 -h -f $Certs_dir/${1}/${1}_host_rsa_key && \
        echo -e "\nNew SSH keys created - $Certs_dir/${1}/${1}_host_rsa_key, $Certs_dir/${1}/${1}_host_rsa_key.pub" || \
        echo -e "\nSSH Keys found - $Certs_dir/${1}/${1}_host_rsa_key, $Certs_dir/${1}/${1}_host_rsa_key.pub - these will be re-used."

    echo -e "Sign the new keys for ${1}"
    # Sign the public key
    [ ! -f $Certs_dir/${1}/${1}_host_rsa_key-cert.pub ] && \
        ssh-keygen -s $Int_CA_dir/${1}/${1}-host-ca -I hashistack_server -h -V -5m:+52w $Certs_dir/${1}/${1}_host_rsa_key.pub && \
        echo -e "\nNew SSH CERTIFICATE created - $Certs_dir/${1}/${1}_host_rsa_key-cert.pub" || \
        echo -e "\nSSH CERTIFICATE found - $Certs_dir/${1}/${1}_host_rsa_key-cert.pub - this will be re-used."        

    # Now copy ${1}_host_rsa_key.pub, ${1}_host_rsa_key-cert.pub and ${1}_host_rsa_key to the target system
    # e.g. /etc/ssh/.
    # Configure the target system to present the host key when ssh is used
    # e.g. grep -qxF 'HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' /etc/ssh/sshd_config || echo 'HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' | sudo tee -a /etc/ssh/sshd_config

    echo -e "\nNow copy ${1}_host_rsa_key.pub, ${1}_host_rsa_key-cert.pub and ${1}_host_rsa_key to the target system"
    echo -e "\nConfigure the target system to present the host key when ssh is used"
    echo -e "\ne.g. grep -qxF 'HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' /etc/ssh/sshd_config || echo 'HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' | sudo tee -a /etc/ssh/sshd_config\n"
    echo -e "\nNow configure the ssh clients to accept the Host Signed Certificate e.g. $Int_CA_dir/${1}/${1}-host-ca.pub \n"
    echo -e "\ngrep -qxF '@cert-authority * ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFmZo/bkvhmUEjx3erXC+rZ1R3htLHtz0VzZNpgQD2sT2KZLW3yBiKYIKgxICM04MQsVHY1k5y4ek/tgnw05m5KOO5KTHxxKjcBKf2EyvwG0o8vnzo6UgweqXEePigAzSGQfcsGp75tVu3qmeLKXtJOo1WaWmTSNH4Qoq89xRiPslCVDi1i2VEPxJi3+eeFL5WO+nBK9Xt28DaXY4B43sgC1KC6DSRUR2JhlgPGMKP2eTE5+UaEldyPVzdIl2j3tLsaURfr+cZ6ryPEE9phT1bjcOSC3A88NrROZH1FvpZpG6NQPXusTWjre/NIz2TdG44AopbFRKAEpMVFw67AJ6oDWHPTrh2TGh3SQEIIZTdhudZIHnwiSBuKUOqyV65KH/mmy5gr8X2miHbM+qh6ISjqwPN6TjAhUPgkjxtwa7K+tDseBoFsrRIgP65hHAIlEFodHUI8Lu3P5HswH39z8ouEDR+qU54z9JO/E0Mw9YQPk19A6jr7o9/06wqSXfkVmS1VwvyZI90Zqrtg4+lZ3Zq/GLDqpxTlakfEAddOd9Ns01GgeSab4mKDwB6r2VTsunXQ4DDJkzxm9ioJmX7Ctv9J50Hqqcv+kiM8jJHrsB4IIrc0Cc/qb08YAo//i44JTuPxs2+FS2ifDmQA+TK5fJxwUIQJ6KDQ+0wB+T6yeYMJw== HOST-CA' /etc/ssh/ssh_known_hosts || echo '@cert-authority * ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFmZo/bkvhmUEjx3erXC+rZ1R3htLHtz0VzZNpgQD2sT2KZLW3yBiKYIKgxICM04MQsVHY1k5y4ek/tgnw05m5KOO5KTHxxKjcBKf2EyvwG0o8vnzo6UgweqXEePigAzSGQfcsGp75tVu3qmeLKXtJOo1WaWmTSNH4Qoq89xRiPslCVDi1i2VEPxJi3+eeFL5WO+nBK9Xt28DaXY4B43sgC1KC6DSRUR2JhlgPGMKP2eTE5+UaEldyPVzdIl2j3tLsaURfr+cZ6ryPEE9phT1bjcOSC3A88NrROZH1FvpZpG6NQPXusTWjre/NIz2TdG44AopbFRKAEpMVFw67AJ6oDWHPTrh2TGh3SQEIIZTdhudZIHnwiSBuKUOqyV65KH/mmy5gr8X2miHbM+qh6ISjqwPN6TjAhUPgkjxtwa7K+tDseBoFsrRIgP65hHAIlEFodHUI8Lu3P5HswH39z8ouEDR+qU54z9JO/E0Mw9YQPk19A6jr7o9/06wqSXfkVmS1VwvyZI90Zqrtg4+lZ3Zq/GLDqpxTlakfEAddOd9Ns01GgeSab4mKDwB6r2VTsunXQ4DDJkzxm9ioJmX7Ctv9J50Hqqcv+kiM8jJHrsB4IIrc0Cc/qb08YAo//i44JTuPxs2+FS2ifDmQA+TK5fJxwUIQJ6KDQ+0wB+T6yeYMJw== HOST-CA' | sudo tee -a /etc/ssh/ssh_known_hosts"
    echo -e "SSH Host CA and Key creation process for ${1} is has completed."
    popd
}

generate_new_user_keys () {
    
    # Create new host keys if they don't already exist
    echo -e "Generate new ssh keys for user ${1}"
    pushd $Certs_dir
    # Generate new keys if required
    ssh-keygen -N '' -C HASHISTACK-${1}-USER-KEY -t rsa -b 2048 -h -f $Certs_dir/${2}/${1}_${2}_user_rsa_key && \
        echo -e "\nNew SSH keys created - $Certs_dir/${2}/${1}_${2}_user_rsa_key, $Certs_dir/${2}/${1}_${2}_user_rsa_key.pub"

    echo -e "Sign the new keys for user ${1}"
    # Sign the user key with the public key
    ssh-keygen -s $Int_CA_dir/${2}/${2}-client-ca -I hashistack_server -n ${1},root,vagrant,graham,pi -V -5:+52w -z 1 $Certs_dir/${2}/${1}_${2}_user_rsa_key.pub && \
        echo -e "\nNew SSH CERTIFICATE created - $Certs_dir/${2}/${1}_${2}_user_rsa_key-cert.pub"      

    # Now copy ${1}_host_rsa_key.pub, ${1}_host_rsa_key-cert.pub and ${1}_host_rsa_key to the target system
    # e.g. /etc/ssh/.
    # Configure the target system to present the host key when ssh is used
    # e.g. grep -qxF 'HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' /etc/ssh/sshd_config || echo 'HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' | sudo tee -a /etc/ssh/sshd_config

    echo -e "\nNow copy $Certs_dir/${2}/${1}_${2}_user_rsa_key, $Certs_dir/${2}/${1}_${2}_user_rsa_key.pub & $Certs_dir/${2}/${1}_${2}_user_rsa_key-cert.pub to the client in the /home/someuser/.ssh directory"
    echo -e "${2} SSH USER CA and Key creation process for ${1} is has completed."
    popd
}

echo -e "\n===================================================="
echo -e "\nStarting to create OpenSSH certificates for lab setup"
echo -e "\n====================================================\n\n"
setup_env

generate_host_certificates ${1}
generate_user_certificates ${1}
generate_new_user_keys ${2} ${1}

echo -e "\nFinished creating OpenSSH certificates lab setup"
echo -e "\n====================================================\n\n\n\n"
