#!/usr/bin/env bash

wget -O - https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/master/scripts/Generate_PKI_Certificates_For_Lab.sh | bash -s consul "server.node.global.consul" "client.node.global.consul" "1.2.3.4" 
wget -O - https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/master/scripts/Generate_PKI_Certificates_For_Lab.sh | bash -s nomad "server.global.nomad" "client.global.nomad" "1.2.3.4" 
wget -O - https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/master/scripts/Generate_PKI_Certificates_For_Lab.sh | bash -s vault "server.global.vault" "client.global.vault" "1.2.3.4" 

