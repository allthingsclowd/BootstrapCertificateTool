#!/usr/bin/env bash

export BootStrapCertTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/0.0.11/scripts/Generate_PKI_Certificates_For_Lab.sh"
export BootstrapSSHTool=
#export BootStrapCertTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/passwordDefault/scripts/Generate_PKI_Certificates_For_Lab.sh"

# Generate Openssl Certs (will use a different script for openSSH keys)
wget -O - ${BootStrapCertTool} | bash -s consul "server.node.global.consul" "client.node.global.consul" "1.2.3.4" 
wget -O - ${BootStrapCertTool} | bash -s nomad "server.global.nomad" "client.global.nomad" "1.2.3.4" 
wget -O - ${BootStrapCertTool} | bash -s vault "server.global.vault" "client.global.vault" "1.2.3.4" 
wget -O - ${BootStrapCertTool} | bash -s wpc "server.global.wpc" "client.global.wpc" "1.2.3.4" 
