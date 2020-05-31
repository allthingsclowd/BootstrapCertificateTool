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
    
  
    IFACE=`route -n | awk '$1 == "192.168.9.0" {print $8;exit}'`
    CIDR=`ip addr show ${IFACE} | awk '$2 ~ "192.168.9" {print $2}'`
    IP=${CIDR%%/24}

  
    IP=${IP:-127.0.0.1}
    if [ "${TRAVIS}" == "true" ]; then
        ROOTCERTPATH=tmp
        LEADER_IP=${IP}
    else
        ROOTCERTPATH=etc
    fi

    export ROOTCERTPATH

    CERTPASSCODE="${CERTPASSCODE:-bananas}"

}

generate_host_ca_signing_keys () {
    
    # ${1} - Environment that host ca signing key is gemerated for 

    echo -e "\n===================================================="
    echo -e "Check to see if a SSH HOST CA KEY for ${1} already exists?"
    # Generate a new OpenSSH CA if one does not already exist
    
    [ ! -f $Int_CA_dir/${1}/${1}-ssh-host-rsa-ca ] && \
        ssh-keygen -t rsa -N '' -C ${1}-SSH-HOST-RSA-CA -b 4096 -f $Int_CA_dir/${1}/${1}-ssh-host-rsa-ca && \
        echo -e "\nNew SSH CA created - $Int_CA_dir/${1}/${1}-ssh-host-rsa-ca" && \
        echo "export ${1}_ssh_host_rsa_ca='`cat $Int_CA_dir/${1}/${1}-ssh-host-rsa-ca`'" \
        >> ${Int_CA_dir}/BootstrapCAs.sh || \
        echo -e "\nSSH CA found - $Int_CA_dir/${1}/${1}-ssh-host-rsa-ca - this will be re-used."
    
    [ -f ${Int_CA_dir}/BootstrapCAs.sh ] && source ${Int_CA_dir}/BootstrapCAs.sh
}

generate_user_ca_signing_keys () {
    # ${1} - Environment that host ca signing key is gemerated for 

    echo -e "\n===================================================="
    echo -e "Check to see if a SSH USER CA KEY for ${1} already exists?"
    # Generate a new OpenSSH CA if one does not already exist
    
    [ ! -f $Int_CA_dir/${1}/${1}-ssh-user-rsa-ca ] && \
        ssh-keygen -t rsa -N '' -C ${1}-SSH-USER-RSA-CA -b 4096 -f $Int_CA_dir/${1}/${1}-ssh-user-rsa-ca && \
        echo -e "\nNew SSH CA created - $Int_CA_dir/${1}/${1}-ssh-user-rsa-ca" && \
        echo "export ${1}_ssh_user_rsa_ca='`cat $Int_CA_dir/${1}/${1}-ssh-user-rsa-ca`'" \
        >> ${Int_CA_dir}/BootstrapCAs.sh || \
        echo -e "\nSSH USER CA found - $Int_CA_dir/${1}/${1}-ssh-user-rsa-ca - this will be re-used."

    [ -f /etc/ssh/${1}-ssh-user-rsa-ca.pub ] && rm -f /etc/ssh/${1}-ssh-user-rsa-ca.pub

    cp $Int_CA_dir/${1}/${1}-ssh-user-rsa-ca.pub /etc/ssh/${1}-ssh-user-rsa-ca.pub
    echo -e "\nConfigure the target system to Trust user certificates signed by the ${1}-SSH-USER-RSA-CA key when ssh certificates are used"
    grep -qxF "TrustedUserCAKeys /etc/ssh/${1}-ssh-user-rsa-ca.pub" /etc/ssh/sshd_config || echo "TrustedUserCAKeys /etc/ssh/${1}-ssh-user-rsa-ca.pub" | sudo tee -a /etc/ssh/sshd_config

    [ -f ${Int_CA_dir}/BootstrapCAs.sh ] && source ${Int_CA_dir}/BootstrapCAs.sh
    echo -e "SSH User(Client) Key creation process for ${1} is has completed."

}


setup_env ${1}
generate_host_ca_signing_keys ${1}
generate_user_ca_signing_keys ${1}