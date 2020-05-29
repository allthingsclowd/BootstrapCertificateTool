#!/usr/bin/env bash

export BootStrapCertTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/0.0.11/scripts/Generate_PKI_Certificates_For_Lab.sh"
export BootstrapSSHTool="https://github.com/allthingsclowd/BootstrapCertificateTool/raw/tweakfortfcloud/scripts/Generate_Access_Certificates.sh"
#export BootStrapCertTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/passwordDefault/scripts/Generate_PKI_Certificates_For_Lab.sh"

# Generate OpenSSH Certs
wget -O - ${BootstrapSSHTool} | bash -s "ssh" "grazzer"
wget -O - ${BootstrapSSHTool} | bash -s "bastion" "grazzer"
# Generate OpenSSL Certs
wget -O - ${BootStrapCertTool} | bash -s consul "server.node.global.consul" "client.node.global.consul" "1.2.3.4" 
wget -O - ${BootStrapCertTool} | bash -s nomad "server.global.nomad" "client.global.nomad" "1.2.3.4" 
wget -O - ${BootStrapCertTool} | bash -s vault "server.global.vault" "client.global.vault" "1.2.3.4" 
wget -O - ${BootStrapCertTool} | bash -s wpc "server.global.wpc" "client.global.wpc" "1.2.3.4"

