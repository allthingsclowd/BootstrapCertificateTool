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



install_cfssl () {
    
    which /usr/bin/cfssl &>/dev/null || {
        echo -e "\nStart CFSSL installation"
        apt install golang-cfssl
        echo -e "\nCFSSL installation complete"
    }

    echo -e "\nCFSSL version: `cfssl version` installed"
    
}

install_go () {
    
    which /usr/local/go/bin/go &>/dev/null || {
        echo -e "\nStart Golang installation"
        echo -e "Create a temporary directory\n"
        sudo mkdir -p /tmp/go_src
        pushd /tmp/go_src
        [ -f go${golang_version}.linux-amd64.tar.gz ] || {
            echo "Download Golang source"
            sudo wget -qnv https://dl.google.com/go/go${golang_version}.linux-amd64.tar.gz
        }
        
        echo "Extract Golang source"
        sudo tar -C /usr/local -xzf go${golang_version}.linux-amd64.tar.gz
        popd
        echo "Remove temporary directory"
        sudo rm -rf /tmp/go_src
        echo "Edit profile to include path for Go"
        echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" | sudo tee -a /etc/profile
        echo "Ensure others can execute the binaries"
        sudo chmod -R +x /usr/local/go/bin/

        source /etc/profile
        echo -e "\nGolang installation complete"  
    }

    echo -e "`/usr/local/go/bin/go version` installed!"
}

convert_for_macOS () {

    # ${1} - key file
    # ${2} - cert file
    # ${3} - CA file

    if [ "${3}" = "ROOT" ] 
    then
        openssl pkcs12 -password pass:${CERTPASSCODE} -export -out ${1}-cert.p12 -inkey ${1} -in ${2} 
    else
        openssl pkcs12 -password pass:${CERTPASSCODE} -export -out ${1}-cert.p12 -inkey ${1} -in ${2} -certfile ${3}
    fi

}

verify_or_generate_root_ca () {

    # Check if a ROOT CA has been provided in the directory
    if [ ! -f "${CA}" ] || [ ! -f "${CA_KEY}" ]
    then

        echo "No Root CA has been found in ${CA_dir} : ? "
        echo "Generating a new Root Certificate Authority now..."
        echo "Using the following configuration for the root CA:"
        cat ${conf_dir}/ca-config.json

        echo "The above details can be changed by editing the data in the ${conf_dir}/ca-config.json file"
        cfssl gencert -initca ${conf_dir}/ca-config.json | cfssljson -bare ${CA_dir}/hashistack-root-ca

        # Convert for mac - openssl pkcs12 -export -out certificate.p12 -inkey privateKey.key -in certificate.crt -certfile CACert.crt
        convert_for_macOS ${CA_dir}/hashistack-root-ca-key.pem ${CA_dir}/hashistack-root-ca.pem ROOT

        # This is a Root CA so the CSR is not required
        [ -f "${CA_dir}/hashistack-root-ca.csr" ] && rm -f ${CA_dir}/hashistack-root-ca.csr


    else
        echo "Existing Root CA has been found and will be used"
    fi

    echo "Validate Root Certificate ${CA}"
    verify_certificate ${CA_dir}/hashistack-root-ca.pem
    
}

verify_or_generate_intermediate_ca () {
    
    # Check if the intermediate CA has been provided in the supplied directory - input parameter ${1}    
    if [ ! -f "${SIGNED_CA_CERT}" ] || [ ! -f "${INT_CA_KEY}" ];
    then
        echo "No Intermediate CA has been found in : ${1} ? "
        echo "Let's check to see if there's a known Root CA"
        # Check if the Root CA exists, if not create that first!
        verify_or_generate_root_ca

        echo "Generating a new Intermediate Certificate Authority now for ${1}"

        export TMP_Int_CA_dir=$Int_CA_dir/${1}
        [ ! -d $TMP_Int_CA_dir ] && mkdir -p $TMP_Int_CA_dir        

        sed 's/Root/'"${1}"' Intermediate/g' $conf_dir/ca-config.json > $Int_CA_dir/${1}/${1}-intermediate-ca.json
        cfssl gencert -initca $Int_CA_dir/${1}/${1}-intermediate-ca.json | cfssljson -bare $Int_CA_dir/${1}/${1}-intermediate-ca
        cfssl sign -ca ${CA} -ca-key ${CA_KEY} --config ${Cert_Profiles} -profile intermediate-ca ${Int_CA_dir}/${1}/${1}-intermediate-ca.csr | cfssljson -bare $Int_CA_dir/${1}/${1}-root-signed-intermediate-ca
        
        # Convert for mac - openssl pkcs12 -export -out certificate.p12 -inkey privateKey.key -in certificate.crt -certfile CACert.crt
        convert_for_macOS ${Int_CA_dir}/${1}/${1}-intermediate-ca-key.pem ${Int_CA_dir}/${1}/${1}-root-signed-intermediate-ca.pem  ${CA_dir}/hashistack-root-ca.pem
        
        ls -al ${Int_CA_dir}/${1}/

        # merge root and intermediate certificates to complete chain for verification

        cat ${CA_dir}/hashistack-root-ca.pem ${Int_CA_dir}/${1}/${1}-root-signed-intermediate-ca.pem > ${Int_CA_dir}/${1}/${1}-ca-chain.pem

        echo "New Intermediate Certificate Authority successfully created ${1}"
        echo "Add CA to a sourced file as an environment variable for bootstrapping use later in Terraform Cloud deployments."
        echo "export ${1}_root_signed_intermediate_ca='`cat $Int_CA_dir/${1}/${1}-root-signed-intermediate-ca.pem`'" >> ${Int_CA_dir}/BootstrapCAs.sh
        echo "export ${1}_intermediate_ca_key='`cat ${Int_CA_dir}/${1}/${1}-intermediate-ca-key.pem`'" >> ${Int_CA_dir}/BootstrapCAs.sh

    else
        echo "Existing Intermediate CA for ${1} has been found and will be used"
        echo "The Root CA will not be required or used."
    fi


 

    echo "Validate Intermediate Certificate for ${1}"
    verify_certificate $Int_CA_dir/${1}/${1}-root-signed-intermediate-ca.pem


}

generate_application_certificates () {

    # ${1} : The application that the certificates are being created for
    # ${-} : This should point to the CA key without the `.pem` or `-key.pem` extensions or that is to be used for signing the leaf certificates
    # ${2} : The application specific server DNS hostname e.g. Consul requires server.node.global.consul
    # ${3} : The application specific peer DNS hostname e.g. Consul requires client.node.global.consul
    # ${4} : Node IP Address

    # Create leaf certificates with profiles for servers, peers and clients
    # Clarification on my definitions
    # servers - these are the nodes hosting the applications that are provideing the service
    # peers - these are actually the client servers that talk to the application servers (confusing with client certs)
    # clients - these are the certs that I plan to use to access the application services remotely using cli e.g. curl or browser

    echo "Checking for an Intermediate CA for ${1}"
    # Check if the Intermediate CA exists, if not create that first!
    export SIGNED_CA_CERT=$Int_CA_dir/${1}/${1}-root-signed-intermediate-ca.pem
    export INT_CA_KEY=$Int_CA_dir/${1}/${1}-intermediate-ca-key.pem
    verify_or_generate_intermediate_ca ${1}

    echo "Start creating Leaf Certificates for ${1}"
    export TMP_Cert_dir=$Certs_dir/${1}
    [ ! -d $TMP_Cert_dir ] && mkdir -p $TMP_Cert_dir

    sed 's/app-specific-dns-hostname/'"${2}"'/g' $conf_dir/server-config.json > $Certs_dir/${1}/${1}-server-config.json
    sed 's/app-specific-dns-hostname/'"${3}"'/g' $conf_dir/peer-config.json > $Certs_dir/${1}/${1}-peer-config.json
    sed -i -e 's/add-ip-address/'"${4}"'/g' $Certs_dir/${1}/${1}-server-config.json
    sed -i -e 's/add-ip-address/'"${4}"'/g' $Certs_dir/${1}/${1}-peer-config.json
    sed -i -e 's/hostname/'"${HOSTNAME}.hashistack.ie"'/g' $Certs_dir/${1}/${1}-server-config.json
    sed -i -e 's/hostname/'"${HOSTNAME}.hashistack.ie"'/g' $Certs_dir/${1}/${1}-peer-config.json
   
    echo "Leaf Certificates for ${1}"

    cp -f $conf_dir/client-config.json $Certs_dir/${1}/${1}-client-config.json
    
    echo "Debug ===> ${SIGNED_CA_CERT}, ${INT_CA_KEY}"

    cfssl gencert -ca=${SIGNED_CA_CERT} -ca-key=${INT_CA_KEY} -config=$conf_dir/certificate-profiles.json -profile=client $Certs_dir/${1}/${1}-client-config.json | cfssljson -bare $Certs_dir/${1}/${1}-cli
    cfssl gencert -ca=${SIGNED_CA_CERT} -ca-key=${INT_CA_KEY} -config=$conf_dir/certificate-profiles.json -profile=server $Certs_dir/${1}/${1}-server-config.json | cfssljson -bare $Certs_dir/${1}/${1}-server
    cfssl gencert -ca=${SIGNED_CA_CERT} -ca-key=${INT_CA_KEY} -config=$conf_dir/certificate-profiles.json -profile=peer $Certs_dir/${1}/${1}-peer-config.json | cfssljson -bare $Certs_dir/${1}/${1}-peer

    # placing certificates into directories for lab environment
    mkdir --parent /${ROOTCERTPATH}/${1}.d/pki/tls/private /${ROOTCERTPATH}/${1}.d/pki/tls/certs /${ROOTCERTPATH}/ssl/certs
    cp $Certs_dir/${1}/${1}-server.pem /${ROOTCERTPATH}/${1}.d/pki/tls/certs/${1}-server.pem
    cp $Certs_dir/${1}/${1}-server-key.pem /${ROOTCERTPATH}/${1}.d/pki/tls/private/${1}-server-key.pem
    cp $Certs_dir/${1}/${1}-peer.pem /${ROOTCERTPATH}/${1}.d/pki/tls/certs/${1}-peer.pem
    cp $Certs_dir/${1}/${1}-peer-key.pem /${ROOTCERTPATH}/${1}.d/pki/tls/private/${1}-peer-key.pem
    cp $Certs_dir/${1}/${1}-cli.pem /${ROOTCERTPATH}/${1}.d/pki/tls/certs/${1}-cli.pem
    cp $Certs_dir/${1}/${1}-cli-key.pem /${ROOTCERTPATH}/${1}.d/pki/tls/private/${1}-cli-key.pem
    # required for travis ci testing
    cp ${Int_CA_dir}/${1}/${1}-ca-chain.pem /${ROOTCERTPATH}/ssl/certs/${1}-ca-chain.pem

    # install the public CA certificates both Root & Intermediate
    cp ${Int_CA_dir}/${1}/${1}-ca-chain.pem /usr/local/share/ca-certificates/${1}-ca-chain.crt
    update-ca-certificates
    openssl rehash /etc/ssl/certs
    
    echo -e "\nSet Certificate file (644) and directory (755)permissions at /${ROOTCERTPATH}/${1}.d\n"
    chmod -R ug=rwX,o=rX /path
    
    # if this is the final target system a user matching application name will exist
    if id -u "${1}" >/dev/null 2>&1; then
        chown -R ${1}:${1} /${ROOTCERTPATH}/${1}.d
    fi

    echo "Validate Certificates for ${1}"
    verify_certificate $Certs_dir/${1}/${1}-cli.pem

    verify_certificate $Certs_dir/${1}/${1}-peer.pem
    verify_certificate_chain $Certs_dir/${1}/${1}-peer.pem
    verify_certificate $Certs_dir/${1}/${1}-server.pem
    verify_certificate_chain $Certs_dir/${1}/${1}-server.pem   

    echo "Finished generating certificates for data centre with domain ${1}" 

}

verify_certificate () {

    if openssl x509 -in ${1} -text -noout 2> /dev/null
    then
        echo "Success: Valid OpenSSL Certificate Created ${1}"
    else
        echo "Error: Certificate Created is NOT Valid ${1}"
        exit 1
    fi
}

verify_certificate_chain () {


    if openssl verify -verbose -purpose sslserver -CAfile /etc/ssl/certs/ca-certificates.crt ${1} 2> /dev/null
    then
        echo "Certificate Chain Validated Successfully for ${1}"
    else
        echo "Failed to validate certificate chain for ${1}"
        exit 1
    fi

}

echo -e "\n===================================================="
echo -e "\nStarting to create application certificates for ${1}"
echo -e "\n====================================================\n\n"
setup_env
install_go
install_cfssl

# Create some throwaway certs to force the creation of the required CAs
generate_application_certificates ${1} ${2} ${3} ${4}


# # The intermediate certificates will be configured as environment variables to be consumed during platofrm deployment time
# cat /usr/local/bootstrap/Outputs/IntermediateCAs/BootstrapCAs.sh
echo -e "\n===================================================="
echo -e "\nFinished creating certificates for ${1}"
echo -e "\n====================================================\n\n\n\n"
