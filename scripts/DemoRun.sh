#!/usr/bin/env bash

source /usr/local/bootstrap/var.env

# export BootStrapCertTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/${certversion}/scripts/Generate_PKI_Certificates_For_Lab.sh"
# export BootstrapSSHTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/${certversion}/scripts/Generate_Access_Certificates.sh"
# export BootstrapSSHToolCA="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/${certversion}/scripts/BootstrapCAs.sh"

# # Generate OpenSSH Certs
# wget -O - ${BootstrapSSHToolCA} | bash -s "hashistack"
# wget -O - ${BootstrapSSHTool} | bash -s "hashistack" "iac4me" ",81.143.215.2"
# # Generate OpenSSL Certs
# wget -O - ${BootStrapCertTool} | bash -s consul "server.node.global.consul" "client.node.global.consul" "1.2.3.4" 
# wget -O - ${BootStrapCertTool} | bash -s nomad "server.global.nomad" "client.global.nomad" "1.2.3.4" 
# wget -O - ${BootStrapCertTool} | bash -s vault "server.global.vault" "client.global.vault" "1.2.3.4" 
# wget -O - ${BootStrapCertTool} | bash -s wpc "server.global.wpc" "client.global.wpc" "1.2.3.4"
# wget -O - ${BootStrapCertTool} | bash -s nginx "server.global.nginx" "client.global.nginx" "1.2.3.4"

IPS=`hostname -I | sed 's/ /,/g' | sed 's/,*$//g'`
certversion=0.0.23
export BootstrapSSHTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/${certversion}/scripts/BootStrapMe.sh"
# Generate OpenSSH Certs
wget -O - ${BootstrapSSHTool} | bash -s - -H -n BASTIONHOST -h ${HOSTNAME} -i ${IPS} -a *.hashistack.ie,hashistack.ie -p 81.143.215.2 -s
wget -O - ${BootstrapSSHTool} | bash -s - -U -n BASTIONUSER -u iac4me -b "iac4me,graham,grazzer,pi,root" -s
wget -O - ${BootstrapSSHTool} | bash -s - -U -n PACKERUSER -u packman -b "packman,graham,grazzer,pi,root" -s
