#!/usr/bin/env bash

# export BootStrapCertTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/0.0.1/scripts/Generate_PKI_Certificates_For_Lab.sh"

export BootStrapCertTool="https://github.com/allthingsclowd/BootstrapCertificateTool/blob/master/scripts/Generate_PKI_Certificates_For_Lab.sh"

wget -O - ${BootStrapCertTool} | bash -s consul "server.node.global.consul" "client.node.global.consul" "1.2.3.4" 
wget -O - ${BootStrapCertTool} | bash -s nomad "server.global.nomad" "client.global.nomad" "1.2.3.4" 
wget -O - ${BootStrapCertTool} | bash -s vault "server.global.vault" "client.global.vault" "1.2.3.4" 

