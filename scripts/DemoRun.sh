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

# IPS=`hostname -I | sed 's/ /,/g' | sed 's/,*$//g'`
# certversion=0.0.25
# export BootstrapSSHTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/${certversion}/scripts/BootStrapMe.sh"
# # Generate OpenSSH Certs
# wget -O - ${BootstrapSSHTool} | bash -s - -H -n BASTIONHOST -h ${HOSTNAME} -i ${IPS} -a *.hashistack.ie,hashistack.ie -p 81.143.215.2 -s
# wget -O - ${BootstrapSSHTool} | bash -s - -U -n BASTIONUSER -u iac4me -b "iac4me,graham,grazzer,pi,root" -s
# wget -O - ${BootstrapSSHTool} | bash -s - -U -n PACKERUSER -u packman -b "packman,graham,grazzer,pi,root" -s

# STEP 1 - Initialise the base lab_cert_host
# export BootstrapSSHTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/${certversion}/scripts/BootStrapMe.sh"
# # Generate OpenSSH Certs
# wget -O - ${BootstrapSSHTool} | bash -s - -c -n BASTIONHOST
# wget -O - ${BootstrapSSHTool} | bash -s - -c -n BASTIONUSER
# wget -O - ${BootstrapSSHTool} | bash -s - -c -n PACKERHOST
# wget -O - ${BootstrapSSHTool} | bash -s - -c -n PACKERUSER
# # I'll use these locally
# wget -O - ${BootstrapSSHTool} | bash -s - -U -n PACKERUSER -u packman -b "graham,grazzer,pi,root" -s
# wget -O - ${BootstrapSSHTool} | bash -s - -U -n BASTIONUSER -u iac4me -b "graham,grazzer,pi,root" -s


# STEP 2 Existing nodes -  copy .bootstrap/CA/BootstrapCAs.sh & var.env to the bastion (or target) host
#           Run the following code on the on the bastion/target
#           Ensure SSHD service is restarted to reload the new sshd_config

# $ scp .bootstrap/CA/BootstrapCAs.sh graham@192.168.1.199:/home/graham
# graham@192.168.1.199's password: 
# BootstrapCAs.sh                                                                                                                                                                                            100%   21KB   1.8MB/s   00:00    
# ~/vagrant_workspace/lab_certificate_creation (master)
# $ scp scripts/DemoRun.sh graham@192.168.1.199:/home/graham
# graham@192.168.1.199's password: 
# DemoRun.sh                                                                                                                                                                                                 100% 3461     1.6MB/s   00:00    
# ~/vagrant_workspace/lab_certificate_creation (master)
# $ scp var.env graham@192.168.1.199:/home/graham
# graham@192.168.1.199's password: 
# var.env                                                                                                                                                                                                    100%   53    37.4KB/s   00:00    
# ~/vagrant_workspace/lab_certificate_creation (master)

{ [ -f BootstrapCAs.sh ] && source BootstrapCAs.sh; } || { echo -e "!!!!!!STOP!!!!!!\n Missing BootstrapCAs.sh file \n" && exit 1; }
{ [ -f var.env ] && source var.env; } || { echo -e "!!!!!!STOP!!!!!!\n Missing var.env file \n" && exit 1 }
export BootstrapSSHTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/${certversion}/scripts/BootStrapMe.sh"
# Generate OpenSSH Certs
wget -O - ${BootstrapSSHTool} | bash -s - -H -n BASTIONHOST -h ${HOSTNAME} -s
wget -O - ${BootstrapSSHTool} | bash -s - -U -n BASTIONUSER -u iac4me -b "graham,grazzer,pi,root" -s
systemctl restart sshd

# STEP 3 - On MacBook add BASTIONHOST and PACKERHOST CA certificates to the known_hosts file and verify all is well

