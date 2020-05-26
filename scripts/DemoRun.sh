#!/usr/bin/env bash

#export BootStrapCertTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/0.0.6/scripts/Generate_PKI_Certificates_For_Lab.sh"

export BootStrapCertTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/whoopie/scripts/Generate_PKI_Certificates_For_Lab.sh"

wget -O - ${BootStrapCertTool} | bash -s consul "server.node.global.consul" "client.node.global.consul" "1.2.3.4" 
wget -O - ${BootStrapCertTool} | bash -s nomad "server.global.nomad" "client.global.nomad" "1.2.3.4" 
wget -O - ${BootStrapCertTool} | bash -s vault "server.global.vault" "client.global.vault" "1.2.3.4" 
wget -O - ${BootStrapCertTool} | bash -s bastion "server.global.bastion" "client.global.bastion" "1.2.3.4"
wget -O - ${BootStrapCertTool} | bash -s ssh "server.global.ssh" "client.global.ssh" "1.2.3.4" 

