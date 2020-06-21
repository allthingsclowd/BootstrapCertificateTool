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
USER=""
PRINCIPALS=""
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
USERCERT="FALSE"

# Constants - FILE PATHS
readonly baseDir="/usr/local/bootstrap"
readonly defaultRoot=".bootstrap"
readonly defaultSSH="SSH"
readonly defaultSSL="SSL"
readonly rootCA="CA"
readonly intermediateCA="IntCA"
readonly leafCerts="Leaf"
readonly sshKeys="Key"

#[ ! -z ${TRAVIS} ] && readonly baseDir="${TRAVIS_BUILD_DIR}" || readonly baseDir="/usr/local/bootstrap"                                  

# Define the script usage instructions                                         
usage() {                                      
  echo "Usage: ${0} -r -n NAME to reinitialise an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -c -n NAME to create an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -d -n NAME to delete an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -R -n NAME to reinitialise an OpenSSL Certificate Authority" 1>&2
  echo "Usage: ${0} -C -n NAME to create an OpenSSL Certificate Authority" 1>&2
  echo "Usage: ${0} -D -n NAME to delete an OpenSSL Certificate Authority" 1>&2
  echo "Usage: ${0} -H -n NAME -h HOSTNAME [-s SET THE KEYS] to create an OpenSSH HostKey" 1>&2
  echo "Usage: ${0} -U -n NAME -u USERNAME -b {string of comma separated principals e.g. 'graham,fred,brian'} [-s create user account and copy keys to target] to create an OpenSSH HostKey" 1>&2
  echo "Usage: ${0} -Z Nuke All Certificates!!!" 1>&2

}

# set a timestamp on old keys
timestamp() {
  date +"%T"
}



# What to do on failure routine
exit_abnormal() {                              
  usage
  exit 1
}

tweet() {

  echo "put a cleaner messaging routine here"

}

# Delete EVERYTHING!!!!!
nuke_everything() {

  # if the defaultRoot directory exists (-d) then delete it forcefully
  [ -d "${baseDir}/${defaultRoot}" ] && \
    rm -rf ${baseDir}/${defaultRoot} && \
    echo -e "Successfully removed ALL certificates by deleting ${baseDir}/${defaultRoot}\n" || \
    echo -e "Failed to delete ${baseDir}/${defaultRoot}\n"

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
        echo "export ${NAME}_ssh_rsa_ca='`cat ${caFile} | openssl base64 -A`'" \
        >> ${bootStrapFile} && \
        echo "export ${NAME}_ssh_rsa_ca_pub='`cat ${caFile}.pub | openssl base64 -A`'" \
        >> ${bootStrapFile}
    
    [ -f ${bootStrapFile} ] && source ${bootStrapFile}

    echo -e "SSH Root Certificate Authority Initialisation Process Complete"

}

verify_ca_signing_keys() {

    local caDir=${baseDir}/${defaultRoot}/${rootCA}/${defaultSSH}/${NAME}
    local caFile=${caDir}/${NAME}-ssh-rsa-ca
    local bootStrapFile=${baseDir}/${defaultRoot}/${rootCA}/BootstrapCAs.sh

    # Check that CA signing key is available
    export caEnv="${NAME}"_ssh_rsa_ca
    export caPubEnv="${NAME}"_ssh_rsa_ca_pub

    if { [ -z "${!caEnv}" ] || [ -z "${!caPubEnv}" ] }; then
        echo -e "\n${!caEnv} or ${!caPubEnv} environment variable need to be set\n"
        # load the signing keys into memory
        if [ -f "${bootStrapFile}" ]; then
          echo -e "\nSourcing the signing key environment variables from: ${bootStrapFile}\n"
          source ${bootStrapFile}
          echo -e "\nBoth ${!caEnv:-'Missing'} and ${!caPubEnv:-'Missing'} should now be set\n"

          if { [ -z "${!caEnv}" ] || [ -z "${!caPubEnv}" ] }; then
            echo -e "\nBANG! No signing keys found in ${bootStrapFile} to commence bootstrap process\n"
            exit 1
          fi
        else
          echo -e "\nBANG! No signing keys file found at ${bootStrapFile} to commence bootstrap process\n"
          exit 1
        fi
    fi
        
    echo -e "\nCA signing keys found ${!caEnv} and ${!caPubEnv} - starting to build new files\n"
    [ -d ${caDir} ] || mkdir -p ${caDir}
    eval echo "$"${NAME}_ssh_rsa_ca | openssl base64 -d -A > ${caFile}.tmp        
    eval echo "$"${NAME}_ssh_rsa_ca_pub | openssl base64 -d -A > ${caFile}.pub.tmp

    ls -al ${caFile}.tmp ${caFile}.pub.tmp
    cat ${caFile}.tmp ${caFile}.pub.tmp
    
    chmod 600 ${caFile}.tmp
    chmod 644 ${caFile}.pub.tmp

}

generate_and_configure_new_user_keys() {

    local caDir=${baseDir}/${defaultRoot}/${rootCA}/${defaultSSH}/${NAME}
    local caFile=${caDir}/${NAME}-ssh-rsa-ca
    local tmpDir=${baseDir}/${defaultRoot}/${sshKeys}/${defaultSSH}/${NAME}
    local bootStrapFile=${baseDir}/${defaultRoot}/${rootCA}/BootstrapCAs.sh
    local keyFile=${tmpDir}/${USER}-id_rsa

    # Check that CA signing key is available
    verify_ca_signing_keys
    
    # Create directories
    [ -d ${tmpDir} ] || mkdir -p ${tmpDir}
    
    pushd ${tmpDir}

    # Create new host keys if they don't already exist
    echo -e "Generate new ssh keys for user ${USER}"
    
    # Remove obsolete keys
    [ -f "${keyFile}" ] && rm -rf ${keyFile} ${keyFile}.pub ${keyFile}-cert.pub
   
    # Generate new keys
    ssh-keygen -N '' -C ${USER}-${NAME}-USER-KEY -t rsa -b 4096 -h -f ${keyFile} && \
        echo -e "\nNew SSH keys created - ${keyFile}, ${keyFile}.pub"
    
    echo -e "Sign the new keys for user ${USER}"
    # Sign the user key with the public key
    ssh-keygen -s ${caFile}.tmp -I ${USER}-${NAME}-user-key -n ${USER},${PRINCIPALS} -V -5:+52w -z 1 ${keyFile}.pub && \
        echo -e "\nNew SSH CERTIFICATE created - ${keyFile}-cert.pub"      
    chmod 600 ${keyFile}
    chmod 644 ${keyFile}.pub
    chmod 644 ${keyFile}-cert.pub

    echo -e "\n${NAME} SSH USER CA and Key creation process for ${USER} has completed."

    # If set option, -s, is selected create user on host and move keys into place 
    if [ ! "${SETKEY}" == "FALSE" ]; then

        if ! grep "\<"${USER}"\>" /etc/passwd >/dev/null 2>&1; then
          
          echo "Creating ${USER} user with ssh access"
          useradd --create-home --home-dir /home/${USER} --shell /bin/bash ${USER}
          usermod -aG sudo ${USER}
          
        fi

        [ -d "/home/${USER}/.ssh" ] || mkdir -p /home/${USER}/.ssh
        cp ${keyFile} /home/${USER}/.ssh/.
        cp ${keyFile}.pub /home/${USER}/.ssh/.
        cp ${keyFile}-cert.pub /home/${USER}/.ssh/.
        chmod 700 /home/${USER}/.ssh
        chmod 600 /home/${USER}/.ssh/${USER}-id_rsa
        chmod 644 /home/${USER}/.ssh/${USER}-id_rsa.pub
        chmod 644 /home/${USER}/.ssh/${USER}-id_rsa-cert.pub
        chown -R ${USER}:${USER} /home/${USER}/

        echo -e "\nMove the TrustedUserCAKeys into Place\n"

        [ -f "${caFile}".pub ] && rm -f ${caFile} ${caFile}.pub

        # Move the USER CA Public signing key into the sshd_config file
        cp -f ${caFile}.pub.tmp /etc/ssh/${NAME}-ssh-user-rsa-ca.pub

        # Remove existing lines that match this configuration
        sed -i '/^TrustedUserCAKeys/d' /etc/ssh/sshd_config
        echo -e "\nConfigure the target system to Trust user certificates signed by the ${NAME}-SSH-USER-RSA-CA key when ssh certificates are used"
        # This first grep will fail everytime because of the above deletion...tidy later
        grep -qxF "TrustedUserCAKeys /etc/ssh/${NAME}-ssh-user-rsa-ca.pub" /etc/ssh/sshd_config || echo "TrustedUserCAKeys /etc/ssh/${NAME}-ssh-user-rsa-ca.pub" | sudo tee -a /etc/ssh/sshd_config

        chmod 644 /etc/ssh/${NAME}-ssh-user-rsa-ca.pub
        echo -e "\nTrustedUserCAKeys configured."
        
    fi
    
    # SECURITY - remove the private signing key - in realworld scenarios (production) this key should NEVER leave the signing server - flawed bootstrapping process
   rm -rf ${caFile}.tmp
   rm -rf ${caFile}.pub.tmp
   popd
    
    echo -e "\n==========USER Keys Creation Completed Successfully================"
}



generate_and_configure_new_host_keys() {

    local caDir=${baseDir}/${defaultRoot}/${rootCA}/${defaultSSH}/${NAME}
    local caFile=${caDir}/${NAME}-ssh-rsa-ca
    local tmpDir=${baseDir}/${defaultRoot}/${sshKeys}/${defaultSSH}/${NAME}
    local bootStrapFile=${baseDir}/${defaultRoot}/${rootCA}/BootstrapCAs.sh
    local keyFile=${tmpDir}/${TARGETNAME}-ssh-rsa-host-key

    # Check that CA signing key is available
    verify_ca_signing_keys  
    
    # Create new host keys
    echo -e "\nGenerate new ssh keys for ${TARGETNAME} HOST Key CERTIFICATES\n"
    [ ! -d "${tmpDir}" ] && mkdir -p "${tmpDir}"
    # remove previous files
    [ -f "${keyFile}" ] && rm -rf ${keyFile} ${keyFile}.pub ${keyFile}-cert.pub

    # create new host key
    ssh-keygen -N '' -C ${TARGETNAME}-SSH-HOST-RSA-KEY -t rsa \
                -b 4096 -h \
                -f ${keyFile} && \
        echo -e "\nNew SSH keys created - ${keyFile}, ${keyFile}.pub\n" || \
        echo -e "\nError creating ssh host key.\n"

    echo -e "\nSign the new keys for ${TARGETNAME} \n"
    # Sign the public key
    ssh-keygen -s ${caFile}.tmp -I ${TARGETNAME}_hashistack_server \
               -h  \
               -V -5m:+52w ${keyFile}.pub && \
        echo -e "\nNew SIGNED SSH CERTIFICATE created - ${keyFile}-cert.pub\n" || \
        echo -e "\nError signing ssh host key.\n"        

    if [ ! "${SETKEY}" == "FALSE" ]; then
      
      # delete existing keys if present
      [ -f "/etc/ssh/${TARGETNAME}-ssh-rsa-host-key" ] && mv /etc/ssh/${TARGETNAME}-ssh-rsa-host-key /etc/ssh/${TARGETNAME}-ssh-rsa-host-key.old.$(timestamp) && \
                                                      mv /etc/ssh/${TARGETNAME}-ssh-rsa-host-key.pub /etc/ssh/${TARGETNAME}-ssh-rsa-host-key.pub.old.$(timestamp) && \
                                                      mv /etc/ssh/${TARGETNAME}-ssh-rsa-host-key-cert.pub /etc/ssh/${TARGETNAME}-ssh-rsa-host-key-cert.pub.old.$(timestamp)
      cp ${keyFile} /etc/ssh/${TARGETNAME}-ssh-rsa-host-key
      cp ${keyFile}.pub /etc/${TARGETNAME}-ssh-rsa-host-key.pub
      cp ${keyFile}-cert.pub /etc/ssh/${TARGETNAME}-ssh-rsa-host-key-cert.pub
      
      chmod 700 /etc/ssh/${TARGETNAME}-ssh-rsa-host-key
      chmod 644 /etc/ssh/${TARGETNAME}-ssh-rsa-host-key.pub
      chmod 644 /etc/ssh/${TARGETNAME}-ssh-rsa-host-key-cert.pub

      echo -e "\nConfigure the target system to present the host key when ssh is used\n"      
      
      # Remove existing lines that match this configuration
      sed -i '/^HostCertificate/d' /etc/ssh/sshd_config
      sed -i '/^HostKey/d' /etc/ssh/sshd_config

      # this should not match as I've just deleted the entry above
      grep -qxF "HostCertificate /etc/ssh/${TARGETNAME}-ssh-rsa-host-key-cert.pub" /etc/ssh/sshd_config || echo "HostCertificate /etc/ssh/${TARGETNAME}-ssh-rsa-host-key-cert.pub" | sudo tee -a /etc/ssh/sshd_config
      grep -qxF "HostKey /etc/ssh/${TARGETNAME}-ssh-rsa-host-key" /etc/ssh/sshd_config || echo "HostKey /etc/ssh/${TARGETNAME}-ssh-rsa-host-key" | sudo tee -a /etc/ssh/sshd_config
      
      
      echo -e "\nConfigure the target system also accept host keys from other certified systems - when acting as a client\n"
      export SSH_HOST_RSA_PUBLIC_SIGNING_CA=`cat ${caFile}.pub.tmp`
      # remove previos keys
      sed -i '/@cert-authority \*.*/d' /etc/ssh/ssh_known_hosts
      grep -qxF "@cert-authority * ${SSH_HOST_RSA_PUBLIC_SIGNING_CA}" /etc/ssh/ssh_known_hosts || echo "@cert-authority * ${SSH_HOST_RSA_PUBLIC_SIGNING_CA}" | sudo tee -a /etc/ssh/ssh_known_hosts

    fi
    
    # SECURITY - remove the private signing key - in realworld scenarios (production) this key should NEVER leave the signing server - flawed bootstrapping process
    rm -rf ${caFile}.tmp
    rm -rf ${caFile}.pub.tmp

    echo -e "\n\nSSH Host Key creation process for ${TARGETNAME} is has completed.\n\n"
    
}

# Initialise SSL CA
ssl_init() {

  echo -e "Starting SSL Root Certificate Authority Initialisation Process"
  [ -d "${baseDir}/${defaultRoot}/${rootCA}/${defaultSSL}/${NAME}" ] && \
    echo -e "Directory ${baseDir}/${defaultRoot}/${rootCA}/${defaultSSL}/${NAME} has been found and will be re-used./n" || \
    mkdir -p ${baseDir}/${defaultRoot}/${rootCA}/${defaultSSL}/${NAME}; echo -e "Created ${baseDir}/${defaultRoot}/${rootCA}/${defaultSSL}/${NAME}"

}

# Process all the commandline inputs using BASH getopts - not to be confused with OS getopt
while getopts "rcdRCDZn:Hh:i:a:p:sUu:b:" options; do              
                                              
  case "${options}" in   
    b)
      PRINCIPALS=${OPTARG}
      ;;
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
    U)
      USERKEY="TRUE"                                                                   
      ;;
    u)                                         
      USER=${OPTARG}                           
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
  [ ! "${TARGETNAME}" == "" ]) && generate_and_configure_new_host_keys
([ "${USERKEY}" == "TRUE" ] && [ ! "${NAME}" == "" ] && \
  [ ! "${USER}" == "" ] && [ ! "${PRINCIPALS}" == "" ]) && generate_and_configure_new_user_keys  

exit 0                                        
