#!/usr/bin/env bash

setup_env () {

    set -x

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

    # Check if a CA has been provided in the directory
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
    
}

verify_or_generate_intermediate_ca () {
    
    # Check if the intermediate CA has been provided in the supplied directory - input parameter ${1}
    if [ ! -f "$Int_CA_dir/${1}/${1}.pem" ] || [ ! -f "$Int_CA_dir/${1}/${1}-key.pem" ] || [ ! -f "$Int_CA_dir/${1}/${1}.csr" ]
    then
        # Check if the Root CA exists, if not create that first!
        verify_or_generate_root_ca

        echo "No Intermediate CA has been found in ${1} : ? "
        echo "Generating a new Intermediate Certificate Authority now for ${1}"

        export TMP_Int_CA_dir=$Int_CA_dir/${1}
        [ ! -d $TMP_Int_CA_dir ] && mkdir -p $TMP_Int_CA_dir        

        sed 's/Root/${1} Intermediate/g' $conf_dir/ca-config.json > $conf_dir/${1}-intermediate-ca.json
        cfssl gencert -initca $conf_dir/${1}-intermediate-ca.json | cfssljson -bare $Int_CA_dir/${1}/${1}-intermediate-ca
        cfssl sign -ca ${CA} -ca-key ${CA_KEY} --config ${Cert_Profiles} -profile intermediate-ca ${Int_CA_dir}/${1}/${1}-intermediate-ca.csr | cfssljson -bare $Int_CA_dir/${1}/${1}-ca
        ls -al $Int_CA_dir/${1}/

    else
        echo "Existing Intermediate CA for ${1} has been found and will be used"
    fi
}

setup_env
install_go
install_cfssl
verify_or_generate_intermediate_ca consul

