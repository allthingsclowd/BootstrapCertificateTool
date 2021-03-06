#!/usr/bin/env bash

setup_env () {

    set -x

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

    [ ! -d $Certs_dir/${1} ] && mkdir -p $Certs_dir/${1}
    [ ! -d $Int_CA_dir/${1} ] && mkdir -p $Int_CA_dir/${1}
    
  
    IPS=`hostname -I | sed 's/ /,/g' | sed 's/,*$//g'`

  
    IP=${IP:-127.0.0.1}
    if [ "${TRAVIS}" == "true" ]; then
        ROOTCERTPATH=tmp
        LEADER_IP=${IP}
    else
        ROOTCERTPATH=etc
    fi

    export ROOTCERTPATH

    CERTPASSCODE="${CERTPASSCODE:-bananas}"

    source ${Int_CA_dir}/BootstrapCAs.sh

}

generate_new_ssh_host_keys () {

    # ${1} - Environment that host ca signing key is gemerated for
    # ${2} - ip address

    # Create new host keys
    echo -e "Generate new ssh keys for ${HOSTNAME} HOST Key CERTIFICATES"
    pushd $Certs_dir
    
    # delete existing keys if present
    [ -f /etc/ssh/ssh_host_rsa_key ] && rm -f /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key.pub /etc/ssh/ssh_host_rsa_key-cert.pub

    # create new host keys
    [ ! -f /etc/ssh/ssh_host_rsa_key ] && \
        ssh-keygen -N '' -C ${HOSTNAME}-${1}-SSH-HOST-RSA-KEY -t rsa -b 4096 -h -n *.hashistack.ie,hashistack.ie,127.0.0.1,${HOSTNAME},${IPS}${2} -f /etc/ssh/ssh_host_rsa_key && \
        echo -e "\nNew SSH keys created - /etc/ssh/ssh_host_rsa_key, /etc/ssh/ssh_host_rsa_key.pub" || \
        echo -e "\nSSH Keys found THIS IS AN ERROR!!!."

    # Check that CA signing key is available
    HOSTCA=${1}_ssh_host_rsa_ca
    [ ! -z ${1}_ssh_host_rsa_ca ] && mkdir -p /tmp/${1}/ && eval 'echo "${'"${HOSTCA}"'}"' > /tmp/${1}/${1}-ssh-host-rsa-ca || echo -e "\nSSH CA Keys NOT FOUND THIS IS AN ERROR!!!. Check environment variables"
    
    chmod 600 /tmp/${1}/${1}-ssh-host-rsa-ca
    cat /tmp/${1}/${1}-ssh-host-rsa-ca

    # Check that CA signing pub key is available
    HOSTCAPUB=${1}_ssh_host_rsa_ca_pub
    [ ! -z ${1}_ssh_host_rsa_ca_pub ] && mkdir -p /tmp/${1}/ && eval 'echo "${'"${HOSTCAPUB}"'}"' > /etc/ssh/${1}-ssh-host-rsa-ca.pub || echo -e "\nSSH CA Keys NOT FOUND THIS IS AN ERROR!!!. Check environment variables"
    
    chmod 644 /etc/ssh/${1}-ssh-host-rsa-ca.pub


    echo -e "Sign the new keys for ${HOSTNAME}"
    # Sign the public key
    [ ! -f /etc/ssh/ssh_host_rsa_key-cert.pub ] && \
        ssh-keygen -s /tmp/${1}/${1}-ssh-host-rsa-ca -I ${HOSTNAME}_hashistack_server -h -n *.hashistack.ie,hashistack.ie,127.0.0.1,${HOSTNAME},${IPS}${2} -V -5m:+52w /etc/ssh/ssh_host_rsa_key.pub && \
        echo -e "\nNew SIGNED SSH CERTIFICATE created - /etc/ssh/ssh_host_rsa_key-cert.pub" || \
        echo -e "\nSSH CERTIFICATE found THIS IS AN ERROR!!!."        

    # SECURITY - remove the private signing key - in realworld scenarios (production) this key should NEVER leave the signing server - flawed bootstrapping process
    rm -rf /tmp/${1}/${1}-ssh-host-rsa-ca

    echo -e "\nConfigure the target system to present the host key when ssh is used"
    grep -qxF 'HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' /etc/ssh/sshd_config || echo 'HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' | sudo tee -a /etc/ssh/sshd_config
    grep -qxF 'HostKey /etc/ssh/ssh_host_rsa_key' /etc/ssh/sshd_config || echo 'HostKey /etc/ssh/ssh_host_rsa_key' | sudo tee -a /etc/ssh/sshd_config
    echo -e "\nConfigure the target system also accept host keys from other certified systems - when acting as a client"
    export SSH_HOST_RSA_PUBLIC_SIGNING_CA=`cat $Int_CA_dir/${1}/${1}-ssh-host-rsa-ca.pub`
    grep -qxF "@cert-authority * ${SSH_HOST_RSA_PUBLIC_SIGNING_CA}" /etc/ssh/ssh_known_hosts || echo "@cert-authority * ${SSH_HOST_RSA_PUBLIC_SIGNING_CA}" | sudo tee -a /etc/ssh/ssh_known_hosts

    chmod 700 /etc/ssh/ssh_host_rsa_key
    chmod 644 /etc/ssh/ssh_host_rsa_key.pub
    chmod 644 /etc/ssh/ssh_host_rsa_key-cert.pub
    
    [ -d $Certs_dir/${1}-host-keys/${HOSTNAME} ] || mkdir -p $Certs_dir/${1}-host-keys/${HOSTNAME}
    cp /etc/ssh/ssh_host_rsa_key* $Certs_dir/${1}-host-keys/${HOSTNAME}/.

    echo -e "SSH Host Key creation process for ${1} is has completed."
    popd
}

create_ssh_user () {
  
  if ! grep ${1} /etc/passwd >/dev/null 2>&1; then
    
    echo "Creating ${1} user with ssh access"
    useradd --create-home --home-dir /home/${1} --shell /bin/bash ${1}
    usermod -aG sudo ${1}
    mkdir -p /home/${1}/.ssh
    chmod 700 /home/${1}/.ssh
    chown -R ${1}:${1} /home/${1}/

  fi

}


generate_new_user_keys () {

    # ${1} - Environment that host ca signing key is gemerated for
    # ${2} - user {string of comma separated usernames "graham,fred,brian"}

    
    # Create new host keys if they don't already exist
    echo -e "Generate new ssh keys for user ${1}"
    pushd $Certs_dir



    [ -f /home/${2}/.ssh/id_rsa ] && rm -f /home/${2}/.ssh/id_rsa*
    # Generate new keys
    ssh-keygen -N '' -C ${1}-${2}-USER-KEY -t rsa -b 4096 -h -f /home/${2}/.ssh/id_rsa && \
        echo -e "\nNew SSH keys created - /home/${2}/.ssh/id_rsa, /home/${2}/.ssh/id_rsa.pub"

    # Check that USER CA signing key is available
    CLIENTCA=${1}_ssh_user_rsa_ca
    [ ! -z ${1}_ssh_user_rsa_ca ] && mkdir -p /tmp/${1}/ && eval 'echo "${'"${CLIENTCA}"'}"' > /tmp/${1}/${1}-ssh-user-rsa-ca || echo -e "\nSSH CA Keys NOT FOUND THIS IS AN ERROR!!!. Check environment variables"
    
    chmod 600 /tmp/${1}/${1}-ssh-user-rsa-ca
    cat /tmp/${1}/${1}-ssh-user-rsa-ca
    
    echo -e "Sign the new keys for user ${2}"
    # Sign the user key with the public key
    ssh-keygen -s /tmp/${1}/${1}-ssh-user-rsa-ca -I ${1}-${2}-user-key -n ${2},grazzer,root,vagrant,graham,pi -V -5:+52w -z 1 /home/${2}/.ssh/id_rsa.pub && \
        echo -e "\nNew SSH CERTIFICATE created - /home/${2}/.ssh/id_rsa.pub"      
    chmod 600 /home/${2}/.ssh/id_rsa
    chmod 644 /home/${2}/.ssh/id_rsa.pub
    chmod 644 /home/${2}/.ssh/id_rsa-cert.pub
    chown -R ${2}:${2} /home/${2}/.ssh

    # SECURITY - remove the private signing key - in realworld scenarios (production) this key should NEVER leave the signing server - flawed bootstrapping process
    rm -rf /tmp/${1}/${1}-ssh-user-rsa-ca

    [ -d $Certs_dir/${1}-user-keys/${IP}/${2} ] || mkdir -p $Certs_dir/${1}-user-keys/${IP}/${2}
    cp /home/${2}/.ssh/id_rsa* $Certs_dir/${1}-user-keys/${IP}/${2}/.
    echo -e "${1} SSH USER CA and Key creation process for ${2} is has completed."
    popd
}

configure_TrustedUserCAKeys () {
    # ${1} - Environment that host ca signing key is gemerated for 

    echo -e "\n===================================================="
    echo -e "Move the TrustedUserCAKeys into Place"

    [ -f /etc/ssh/${1}-ssh-user-rsa-ca.pub ] && rm -f /etc/ssh/${1}-ssh-user-rsa-ca.pub

    # Check that USER CA signing key is available
    CLIENTCAPUB=${1}_ssh_user_rsa_ca_pub
    [ ! -z ${1}_ssh_user_rsa_ca_pub ] && eval 'echo "${'"${CLIENTCAPUB}"'}"' > /etc/ssh/${1}-ssh-user-rsa-ca.pub || echo -e "\nSSH CA Keys NOT FOUND THIS IS AN ERROR!!!. Check environment variables"
    
    chmod 644 /etc/ssh/${1}-ssh-user-rsa-ca.pub
    cat /etc/ssh/${1}-ssh-user-rsa-ca.pub

    cp $Int_CA_dir/${1}/${1}-ssh-user-rsa-ca.pub /etc/ssh/${1}-ssh-user-rsa-ca.pub
    echo -e "\nConfigure the target system to Trust user certificates signed by the ${1}-SSH-USER-RSA-CA key when ssh certificates are used"
    grep -qxF "TrustedUserCAKeys /etc/ssh/${1}-ssh-user-rsa-ca.pub" /etc/ssh/sshd_config || echo "TrustedUserCAKeys /etc/ssh/${1}-ssh-user-rsa-ca.pub" | sudo tee -a /etc/ssh/sshd_config

    chmod 644 /etc/ssh/${1}-ssh-user-rsa-ca.pub
    echo -e "\nTrustedUserCAKeys configured."

    echo -e "\n===================================================="

}



echo -e "\n===================================================="
echo -e "\nStarting to create OpenSSH certificates for lab setup"
echo -e "\n====================================================\n\n"

# ${1} - Environment Name - e.g. hashistack
# ${3} - Public IP with leading comma (OPTIONAL) - e.g. ",82.2.123.126"
# ${2} - Username - e.g. grazzer

setup_env ${1}
generate_new_ssh_host_keys ${1} ${3}
create_ssh_user ${2}
generate_new_user_keys ${1} ${2}
configure_TrustedUserCAKeys ${1}

echo -e "\nFinished creating OpenSSH certificates lab setup"
echo -e "\n====================================================\n\n\n\n"
