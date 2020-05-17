#!/usr/bin/env bash

setup_env () {

    set +x

    # Binary versions to check for
    [ -f /usr/local/bootstrap/var.env ] && {
        cat /usr/local/bootstrap/var.env
        source /usr/local/bootstrap/var.env
    }

    # Configure Directories
    export conf_dir=/usr/local/bootstrap/conf
    [ ! -d $conf_dir ] && mkdir -p $conf_dir
    export CA_dir=/usr/local/bootstrap/Outputs/RootCA
    [ ! -d $CA_dir ] && mkdir -p $CA_dir
    export Int_CA_dir=/usr/local/bootstrap/Outputs/IntermediateCAs
    [ ! -d $Int_CA_dir ] && mkdir -p $Int_CA_dir
    export Certs_dir=/usr/local/bootstrap/Outputs/Certificates
    [ ! -d $Certs_dir ] && mkdir -p $Certs_dir 
    
    export CA=$CA_dir/hashistack-root-ca.pem
    export CA_KEY=$CA_dir/hashistack-root-ca-key.pem
    export Cert_Profiles=$conf_dir/certificate-profiles.json

    [ -f /usr/local/bootstrap/Outputs/IntermediateCAs/BootstrapCAs.sh ] && {
        source /usr/local/bootstrap/Outputs/IntermediateCAs/BootstrapCAs.sh
    }
    

}



install_cfssl () {
    
    which $HOME/go/bin/cfssl &>/dev/null || {
        echo -e "\nStart CFSSL installation"
        go get -u github.com/cloudflare/cfssl/cmd/cfssl
        go get -u github.com/cloudflare/cfssl/cmd/cfssljson
    }
}

install_go () {
    echo -e "\nStart Golang installation"
    which /usr/local/go/bin/go &>/dev/null || {
        echo "Create a temporary directory"
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
    }

    echo "`go version` successfully installed!"
}

verify_or_generate_root_ca () {

    # Check if a ROOT CA has been provided in the directory
    if [ ! -f "$CA" ] || [ ! -f "$CA_KEY" ]
    then

        echo "No Root CA has been found in $CA_dir : ? "
        echo "Generating a new Root Certificate Authority now..."
        echo "Using the following configuration for the root CA:"
        cat $conf_dir/ca-config.json

        echo "The above details can be changed by editing the data in the ${conf_dir}/ca-config.json file"
        cfssl gencert -initca $conf_dir/ca-config.json | cfssljson -bare $CA_dir/hashistack-root-ca

        # This is a Root CA so the CSR is not required
        [ -f "$CA_dir/hashistack-root-ca.csr" ] && rm -f $CA_dir/hashistack-root-ca.csr


    else
        echo "Existing Root CA has been found and will be used"
    fi

    echo "Validate Root Certificate $CA"
    verify_certificate $CA_dir/hashistack-root-ca
    
}

verify_or_generate_intermediate_ca () {
    
    # Check if the intermediate CA has been provided in the supplied directory - input parameter ${1}
    if [ ! -f "$Int_CA_dir/${1}/${1}-intermediate-ca.pem" ] || [ ! -f "$Int_CA_dir/${1}/${1}-intermediate-ca-key.pem" ] || [ ! -f "$Int_CA_dir/${1}/${1}-intermediate-ca.csr" ]
    then
        echo "No Intermediate CA has been found in ${1} : ? "
        echo "Checking for a Root CA"
        # Check if the Root CA exists, if not create that first!
        verify_or_generate_root_ca
        
        echo "Generating a new Intermediate Certificate Authority now for ${1}"

        export TMP_Int_CA_dir=$Int_CA_dir/${1}
        [ ! -d $TMP_Int_CA_dir ] && mkdir -p $TMP_Int_CA_dir        

        sed 's/Root/'"${1}"' Intermediate/g' $conf_dir/ca-config.json > $Int_CA_dir/${1}/${1}-intermediate-ca.json
        cfssl gencert -initca $Int_CA_dir/${1}/${1}-intermediate-ca.json | cfssljson -bare $Int_CA_dir/${1}/${1}-intermediate-ca
        cfssl sign -ca ${CA} -ca-key ${CA_KEY} --config ${Cert_Profiles} -profile intermediate-ca ${Int_CA_dir}/${1}/${1}-intermediate-ca.csr | cfssljson -bare $Int_CA_dir/${1}/${1}-ca
        ls -al $Int_CA_dir/${1}/

        echo "New Intermediate Certificate Authority successfully created ${1}"
        echo "Add CA to a sourced file as an environment variable for bootstrapping use later"
        echo "export Intermediate_CA_${1}_pem='`cat ${Int_CA_dir}/${1}/${1}-intermediate-ca.pem`'" >> ${Int_CA_dir}/BootstrapCAs.sh
        echo "export Intermediate_CA_${1}_key_pem='`cat ${Int_CA_dir}/${1}/${1}-intermediate-ca-key.pem`'" >> ${Int_CA_dir}/BootstrapCAs.sh

    else
        echo "Existing Intermediate CA for ${1} has been found and will be used"
        echo "The Root CA will not be required or used."
    fi

    echo "Validate Intermediate Certificate for ${1}"
    verify_certificate $Int_CA_dir/${1}/${1}-ca


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
    verify_or_generate_intermediate_ca ${1}

    echo "Start creating Leaf Certificates for ${1}"
    export TMP_Cert_dir=$Certs_dir/${1}
    [ ! -d $TMP_Cert_dir ] && mkdir -p $TMP_Cert_dir

    sed 's/app-specific-dns-hostname/'"${2}"'/g' $conf_dir/server-config.json > $Certs_dir/${1}/${1}-server-config.json
    sed 's/app-specific-dns-hostname/'"${3}"'/g' $conf_dir/peer-config.json > $Certs_dir/${1}/${1}-peer-config.json
    sed -i -e 's/add-ip-address/'"${4}"'/g' $Certs_dir/${1}/${1}-server-config.json
    sed -i -e 's/add-ip-address/'"${4}"'/g' $Certs_dir/${1}/${1}-peer-config.json
    cp -f $conf_dir/client-config.json $Certs_dir/${1}/${1}-client-config.json

    cfssl gencert -ca=$Int_CA_dir/${1}/${1}-intermediate-ca.pem -ca-key=$Int_CA_dir/${1}/${1}-intermediate-ca-key.pem -config=$conf_dir/certificate-profiles.json -profile=client $Certs_dir/${1}/${1}-client-config.json | cfssljson -bare $Certs_dir/${1}/${1}-cli
    cfssl gencert -ca=$Int_CA_dir/${1}/${1}-intermediate-ca.pem -ca-key=$Int_CA_dir/${1}/${1}-intermediate-ca-key.pem -config=$conf_dir/certificate-profiles.json -profile=server $Certs_dir/${1}/${1}-server-config.json | cfssljson -bare $Certs_dir/${1}/${1}-server
    cfssl gencert -ca=$Int_CA_dir/${1}/${1}-intermediate-ca.pem -ca-key=$Int_CA_dir/${1}/${1}-intermediate-ca-key.pem -config=$conf_dir/certificate-profiles.json -profile=peer $Certs_dir/${1}/${1}-peer-config.json | cfssljson -bare $Certs_dir/${1}/${1}-peer

    echo "Validate Certificates for ${1}"
    verify_certificate $Certs_dir/${1}/${1}-cli
    verify_certificate $Certs_dir/${1}/${1}-peer
    verify_certificate $Certs_dir/${1}/${1}-server

}

verify_certificate () {

    if openssl x509 -in ${1}.pem -text -noout 2> /dev/null
    then
        echo "Success: Valid OpenSSL Certificate Created ${1}.pem"
    else
        echo "Error: Certificate Created is NOT Valid ${1}.pem"
    fi
}

echo -e "\nStarting Certification Process"
setup_env
install_go
install_cfssl

# Create some throwaway certs to force the creation of the required CAs
generate_application_certificates ${1} ${2} ${3} ${4}


# The intermediate certificates will be configured as environment variables to be consumed during platofrm deployment time

echo -e "\nFinished Certification Process"
