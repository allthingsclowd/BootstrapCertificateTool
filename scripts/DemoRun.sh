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
{ [ -f var.env ] && source var.env; } || { echo -e "!!!!!!STOP!!!!!!\n Missing var.env file \n" && exit 1; }
export BootstrapSSHTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/${certversion}/scripts/BootStrapMe.sh"
# Generate OpenSSH Certs
wget -O - ${BootstrapSSHTool} | bash -s - -H -n BASTIONHOST -h ${HOSTNAME} -s
wget -O - ${BootstrapSSHTool} | bash -s - -U -n BASTIONUSER -u iac4me -b "graham,grazzer,pi,root" -s
systemctl restart sshd

# STEP 3 - On MacBook add BASTIONHOST and PACKERHOST CA certificates to the known_hosts file and verify all is well by logging in

# STEP 4 - Update the Packer build process to leverage the new ssh Keys in your packer pipeline
# Add the public key for the PACKERUSER created above to the seed file used to deploy ubuntu silently - this is ALL OS specific, in this case ubuntu
# Copy across the BootStrap.sh file from the labcert directory
# Ensure the correct keys are in place
# Review the Certify.sh script to ensure the versions are correct
#
# source /usr/local/bootstrap/var.env
# source /usr/local/bootstrap/.bootstrap/CA/BootstrapCAs.sh


# { [ -f /usr/local/bootstrap/.bootstrap/CA/BootstrapCAs.sh ] && source /usr/local/bootstrap/.bootstrap/CA/BootstrapCAs.sh; } || { echo -e "!!!!!!STOP!!!!!!\n Missing /usr/local/bootstrap/.bootstrap/CA/BootstrapCAs.sh file \n" && exit 1; }
# { [ -f /usr/local/bootstrap/var.env ] && source /usr/local/bootstrap/var.env; } || { echo -e "!!!!!!STOP!!!!!!\n Missing /usr/local/bootstrap/var.env file \n" && exit 1 }
# export BootstrapSSHTool="https://raw.githubusercontent.com/allthingsclowd/BootstrapCertificateTool/${certversion}/scripts/BootStrapMe.sh"
# # Generate OpenSSH Certs
# wget -O - ${BootstrapSSHTool} | bash -s - -H -n PACKERHOST -h ${HOSTNAME} -s
# wget -O - ${BootstrapSSHTool} | bash -s - -U -n PACKERUSER -u packman -b "graham,grazzer,pi,root" -s

# # Create grazzer user account.

# d-i preseed/late_command string \
#     in-target sed -i 's/^%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers; \
#     in-target /bin/sh -c "echo 'Defaults env_keep += \"SSH_AUTH_SOCK\"' >> /etc/sudoers"; \
#     in-target mkdir -p /home/packman/.ssh; \
#     in-target /bin/sh -c "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzgVzATNldsAtFrpXMMpz193itJ4dGK3YxU3eWQXxslQapukBhXyLlnyyw+qzi7H0PWjbCoHjQRUSMguyRhLF7IcXTpf/cF++u/tTEsejbnT2HOCS6obYfZKKF/4ZelRZXHv869mZZUoh+frUk5KxJPjx/4eYFYi2LY0SD//NmT+i6Ip/hfqe24anL/+uya+yZAilPMyPCpLhrd2LLW9tWun+rNRosAPT0h03zCABzS0cpizL7HxbgbnZxyWll5RLqpSigs9Gzk7BX3oedZhZrhKtmvQmhvvSnKhvCQMA6HgsFJ47zd5Cwj1WEwDaFkq8Fec7hFQoPjTT6T9OAHexoSRuQbg3cQcKu/tqSLZDcY8Y5HtpCz3bnhJOnC+1aznpbdoGSBeUJ43c2cIF/lsWgFkjz/I2IsAtrncV9MLQL+c89AJx0E4sJ9/5LsNFQo2FoGa1bewwxtJ/941AZvOP8U4gEja3De+KO3SqrU2rVs6c+J1yG9kMjHhyGORa9ULTosupKUYejA13A9plpbi/Uc6QVmAMTNzAGerwF4iklf3BCqyPzv/6eXU4yz4S834vzTY0lsgipDZSpSog1qWr9CNBe/nkEkawm50tuPZPK0pH1+buIUJZlYUe3USmEiuIg3M+hoEAROg+tc0HlR0KFhPWPt+aZdfbhEpGlFEeBew== packman-PACKERUSER-USER-KEY' >> /home/packman/.ssh/authorized_keys"; \
#     in-target chown -R packman:packman /home/packman/; \
#     in-target chmod -R go-rwx /home/packman/.ssh/authorized_keys; \
#     in-target sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config; \
#     in-target sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config;

# STEP 5 - Update Vagrant Deployment Pipeline for Dev work

# STEP 6 - Update Terraform code for local deployment

# STEP 7 - [Optional] Migrate to TF Cloud and Bootstrap their too :)

