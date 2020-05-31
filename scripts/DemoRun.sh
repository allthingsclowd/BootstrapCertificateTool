#!/usr/bin/env bash

#export BootStrapCertTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/0.0.12/scripts/Generate_PKI_Certificates_For_Lab.sh"
#export BootstrapSSHTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/0.0.12/scripts/Generate_Access_Certificates.sh"
#export BootStrapCertTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/passwordDefault/scripts/Generate_PKI_Certificates_For_Lab.sh"
export BootstrapSSHTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/host_fix/scripts/Generate_Access_Certificates.sh"


# Generate OpenSSH Certs
#wget -O - ${BootstrapSSHTool} | bash -s "ssh" "grazzer"
wget -O - ${BootstrapSSHTool} | bash -s "hashistack" "iac4me" ",81.143.215.2"
# Generate OpenSSL Certs
#wget -O - ${BootStrapCertTool} | bash -s consul "server.node.global.consul" "client.node.global.consul" "1.2.3.4" 
#wget -O - ${BootStrapCertTool} | bash -s nomad "server.global.nomad" "client.global.nomad" "1.2.3.4" 
#wget -O - ${BootStrapCertTool} | bash -s vault "server.global.vault" "client.global.vault" "1.2.3.4" 
#wget -O - ${BootStrapCertTool} | bash -s wpc "server.global.wpc" "client.global.wpc" "1.2.3.4"
#wget -O - ${BootStrapCertTool} | bash -s nginx "server.global.nginx" "client.global.nginx" "1.2.3.4"
