#!/usr/bin/env bash

# This script has been written to simplify the day zero TLS bootstrapping of my development environment

#####################################################################
# This DOES NOT FOLLOW Production Grade Security PKI Best Practices #
#####################################################################

# However, it does vastly improve the security and repeatibility of what 
# I have today in my home development environment.

# In a production environment you would typically leverage a product like 
# HashiCorp Vault (https://www.vaultproject.io/) to simplify everything 
# you see in this script, but ironically this lab is used to build my vault server 
# A chicken and egg scenario!

# Initialise some variables that capture the command line inputs
NAME=""
SSHINIT="FALSE"
SSLINIT="FALSE"
SSHRESET="FALSE"
SSLRESET="FALSE"
SSHDELETE="FALSE"
SSLDELETE="FALSE"
TARGETHOST="FALSE"
TARGETNAME=""
TARGETIPS=""
TARGETDNS=""
PUBLICIP=""
HOSTKEY="FALSE"
SETKEY="FALSE"

# Constants - FILE PATHS
readonly baseDir="/usr/local/bootstrap"
readonly defaultRoot=".bootstrap"
readonly defaultSSH="SSH"
readonly defaultSSL="SSL"
readonly rootCA="CA"
readonly intermediateCA="IntCA"
readonly leafCerts="Leaf"
readonly sshKeys="Key"

[ -z ${TRAVIS} ] && readonly baseDir="${TRAVIS_BUILD_DIR}" || readonly baseDir="/usr/local/bootstrap"                                  

# Define the script usage instructions                                         
usage() {                                      
  echo "Usage: ${0} -r -n NAME to reinitialise an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -c -n NAME to create an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -d -n NAME to delete an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -R -n NAME to reinitialise an OpenSSL Certificate Authority" 1>&2
  echo "Usage: ${0} -C -n NAME to create an OpenSSL Certificate Authority" 1>&2
  echo "Usage: ${0} -D -n NAME to delete an OpenSSL Certificate Authority" 1>&2
  echo "Usage: ${0} -H -n NAME -h HOSTNAME -i IPADDRESSES (hostname -I string) -a DOMAINS -p PUBLICIP -s SET THE KEYS to create an OpenSSH HostKey" 1>&2
  echo "Usage: ${0} -Z Nuke All Certificates!!!" 1>&2

}

# What to do on failure routine
exit_abnormal() {                              
  usage
  exit 1
}

# Delete EVERYTHING!!!!!
nuke_everything() {

  # if the defaultRoot directory exists (-d) then delete it forcefully
  [ -d "${baseDir}/${defaultRoot}" ] && \
    rm -rf ${baseDir}/${defaultRoot} && \
    echo -e "Successfully removed ALL certificates by deleting ${baseDir}/${defaultRoot}/n" || \
    echo -e "Failed to delete ${baseDir}/${defaultRoot}/n"

}

# Initialise SSH CA
ssh_init() {

    local tmpDir=${baseDir}/${defaultRoot}/${rootCA}/${defaultSSH}/${NAME}
    local bootStrapFile=${baseDir}/${defaultRoot}/${rootCA}/BootstrapCAs.sh
    local caFile=${tmpDir}/${NAME}-ssh-rsa-ca
    
    echo -e "Starting SSH Root Certificate Authority Initialisation Process"
    
    # if there's an existing S{NAME} CA then re-use it
    [ -f "${caFile}" ] && \
      echo -e "CA ${caFile} has been found and will be re-used.\n" && \
      return
    
    # Generate a new OpenSSH CA if one does not already exist
    echo -e "Create SSH CA KEY for ${tmpDir}"
    [ ! -d ${tmpDir} ] && mkdir -p ${tmpDir}
    
    [ ! -f ${caFile} ] && \
        echo -e "\nA New SSH HOST CA is being created - ${caFile}" && \
        ssh-keygen -t rsa -N '' -C ${NAME}-SSH-RSA-CA -b 4096 -f ${caFile} && \
        echo "export ${NAME}_ssh_rsa_ca='`cat ${caFile}`'" \
        >> ${bootStrapFile} && \
        echo "export ${NAME}_ssh_rsa_ca_pub='`cat ${caFile}.pub`'" \
        >> ${bootStrapFile}
    
    [ -f ${bootStrapFile} ] && source ${bootStrapFile}

    echo -e "SSH Root Certificate Authority Initialisation Process Complete"

}

generate_and_configure_new_host_keys() {

    local caDir=${baseDir}/${defaultRoot}/${rootCA}/${defaultSSH}/${NAME}
    local caFile=${caDir}/${NAME}-ssh-rsa-ca
    local tmpDir=${baseDir}/${defaultRoot}/${sshKeys}/${defaultSSH}/${NAME}
    local bootStrapFile=${baseDir}/${defaultRoot}/${rootCA}/BootstrapCAs.sh
    local keyFile=${tmpDir}/${TARGETNAME}-ssh-rsa-host-key

    # Create new host keys
    echo -e "Generate new ssh keys for ${TARGETNAME} HOST Key CERTIFICATES"
    [ ! -d ${tmpDir} ] && mkdir -p ${tmpDir}
    
    # create new host key
    ssh-keygen -N '' -C ${TARGETNAME}-SSH-HOST-RSA-KEY -t rsa \
                -b 4096 -h \
                -n ${TARGETDNS},127.0.0.1,${TARGETNAME},${TARGETIPS}${PUBLICIP} \
                -f ${keyFile} && \
        echo -e "\nNew SSH keys created - ${keyFile}, ${keyFile}.pub" || \
        echo -e "\nError creating ssh host key."

    # Check that CA signing key is available
    ( [ ! -z ${NAME}_ssh_rsa_ca ] && mkdir -p ${caDir} && eval 'echo "${'"${NAME}_ssh_rsa_ca"'}"' > ${caFile}.tmp ) || ( echo -e "\nSSH CA Keys NOT FOUND THIS IS AN ERROR!!!. Check environment variables" && exit 1 )
    
    chmod 600 ${caFile}.tmp

    # Check that CA signing pub key is available
    ( [ ! -z ${NAME}_ssh_rsa_ca_pub ] && mkdir -p ${caDir} && eval 'echo "${'"${NAME}_ssh_rsa_ca_pub"'}"' > ${caFile}.pub.tmp ) || ( echo -e "\nSSH CA Public Keys NOT FOUND THIS IS AN ERROR!!!. Check environment variables" && exit 1 )
    
    chmod 644 ${caFile}.pub.tmp

    echo -e "Sign the new keys for ${TARGETNAME}"
    # Sign the public key
    ssh-keygen -s ${caFile} -I ${TARGETNAME}_hashistack_server \
               -h -n ${TARGETDNS},127.0.0.1,${TARGETNAME},${TARGETIPS}${PUBLICIP} \
               -V -5m:+52w ${keyFile}.pub && \
        echo -e "\nNew SIGNED SSH CERTIFICATE created - ${keyFile}-cert.pub" || \
        echo -e "\nError signing ssh host key."        

    if [ ! "${SETKEY}" == "FALSE" ] then
      
      # delete existing keys if present
      [ -f /etc/ssh/ssh_host_rsa_key ] && rm -f /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key.pub /etc/ssh/ssh_host_rsa_key-cert.pub
      cp ${keyFile} /etc/ssh/ssh_host_rsa_key
      cp ${keyFile}.pub /etc/ssh/ssh_host_rsa_key.pub
      cp ${keyFile}-cert.pub /etc/ssh/ssh_host_rsa_key-cert.pub
      
      chmod 700 /etc/ssh/ssh_host_rsa_key
      chmod 644 /etc/ssh/ssh_host_rsa_key.pub
      chmod 644 /etc/ssh/ssh_host_rsa_key-cert.pub

      echo -e "\nConfigure the target system to present the host key when ssh is used"
      grep -qxF 'HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' /etc/ssh/sshd_config || echo 'HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' | sudo tee -a /etc/ssh/sshd_config
      grep -qxF 'HostKey /etc/ssh/ssh_host_rsa_key' /etc/ssh/sshd_config || echo 'HostKey /etc/ssh/ssh_host_rsa_key' | sudo tee -a /etc/ssh/sshd_config
      
      echo -e "\nConfigure the target system to also accept host keys from other certified systems - when acting as a client"
      export SSH_HOST_RSA_PUBLIC_SIGNING_CA=`cat ${caFile}.pub.tmp`
      grep -qxF "@cert-authority * ${SSH_HOST_RSA_PUBLIC_SIGNING_CA}" /etc/ssh/ssh_known_hosts || echo "@cert-authority * ${SSH_HOST_RSA_PUBLIC_SIGNING_CA}" | sudo tee -a /etc/ssh/ssh_known_hosts
    fi
    
    # SECURITY - remove the private signing key - in realworld scenarios (production) this key should NEVER leave the signing server - flawed bootstrapping process
    rm -rf ${caFile}.tmp
    rm -rf ${caFile}.pub.tmp

    echo -e "SSH Host Key creation process for ${TARGETNAME} is has completed."
    
}

# Initialise SSL CA
ssl_init() {

  echo -e "Starting SSL Root Certificate Authority Initialisation Process"
  [ -d "${baseDir}/${defaultRoot}/${rootCA}/${defaultSSL}/${NAME}" ] && \
    echo -e "Directory ${baseDir}/${defaultRoot}/${rootCA}/${defaultSSL}/${NAME} has been found and will be re-used./n" || \
    mkdir -p ${baseDir}/${defaultRoot}/${rootCA}/${defaultSSL}/${NAME}; echo -e "Created ${baseDir}/${defaultRoot}/${rootCA}/${defaultSSL}/${NAME}"

}

# Process all the commandline inputs using BASH getopts - not to be confused with OS getopt
while getopts "rcdRCDZn:h:i:a:p:s" options; do              
                                              
  case "${options}" in   
    s)
      SETKEY="TRUE"
      ;;                      
    p)                                         
      PUBLICIP=${OPTARG}                            
      ;;
    H)                                         
      TARGETHOST="TRUE"                            
      ;;
    h)                                         
      TARGETNAME=${OPTARG}                            
      ;;
    i)                                         
      TARGETIPS=${OPTARG}                          
      ;;
    a)                                         
      TARGETDNS=${OPTARG}                          
      ;;
    r)                                         
      SSHRESET="TRUE"                            
      ;;
    c)                                         
      SSHINIT="TRUE"                          
      ;;
    d)                                         
      SSHDELETE="TRUE"                          
      ;;
    R)                                         
      SSLRESET="TRUE"                          
      ;;    
    C)                                         
      SSLINIT="TRUE"                           
      ;;
    D)                                         
      SSLDELETE="TRUE"                         
      ;;
    Z)                                         
      echo "Are you sure you wish to permanently delete ALL certificates, keys, config and ROOT CAs?"
      select yn in "Yes" "No"; 
      do
        case $yn in
          Yes ) nuke_everything; exit 0;;
          No ) exit_abnormal;;
        esac
      done                       
      ;;
    n)                                         
      NAME=${OPTARG}                          
      ;;
    :)                                         
      echo "Error: -${OPTARG} requires an argument."
      exit_abnormal                            
      ;;
    *)                                         
      exit_abnormal                            
      ;;
  esac
done

([ "${SSHINIT}" == "TRUE" ] && [ ! "${NAME}" == "" ]) && ssh_init
([ "${SSLINIT}" == "TRUE" ] && [ ! "${NAME}" == "" ]) && ssl_init
([ "${TARGETHOST}" == "TRUE" ] && [ ! "${NAME}" == "" ] && \
  [ ! "${TARGETDNS}" == "" ] && [ ! "${TARGETIPS}" == "" ] && \
  [ ! "${TARGETNAME}" == "" ]) && generate_and_configure_new_host_keys  

exit 0                                        