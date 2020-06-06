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

# Constants - FILE PATHS
readonly baseDir="/usr/local/bootstrap"
readonly defaultRoot=".bootstrap"
readonly defaultSSH="SSH"
readonly defaultSSL="SSL"
readonly rootCA="CA"
readonly intermediateCA="IntCA"
readonly leafCerts="Leaf"
readonly sshKeys="Key"                                   

# Define the script usage instructions                                         
usage() {                                      
  echo "Usage: ${0} -r -n NAME to reinitialise an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -c -n NAME to create an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -d -n NAME to delete an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -R -n NAME to reinitialise an OpenSSL Certificate Authority" 1>&2
  echo "Usage: ${0} -C -n NAME to create an OpenSSL Certificate Authority" 1>&2
  echo "Usage: ${0} -D -n NAME to delete an OpenSSL Certificate Authority" 1>&2
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

# Initialise SSH CA directory
ssh_init() {

  echo -e "Starting SSH Root Certificate Authority Initialisation Process"
  [ -d "${baseDir}/${defaultRoot}/${rootCA}/${defaultSSH}/${NAME}" ] && \
    echo -e "Directory ${baseDir}/${defaultRoot}/${rootCA}/${defaultSSH}/${NAME} has been found and will be re-used./n" || \
    mkdir -p ${baseDir}/${defaultRoot}/${rootCA}/${defaultSSH}/${NAME}; echo -e "Created ${baseDir}/${defaultRoot}/${rootCA}/${defaultSSH}/${NAME}"

}
# Process all the commandline inputs using BASH getopts - not to be confused with OS getopt
while getopts "rcdRCDZn:" options; do              
                                              
  case "${options}" in                         
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

[ "${SSHINIT}" == "TRUE" ] && [ ! "${NAME}" == "" ] && ssh_init
  

exit 0                                        