#!/usr/bin/env bash

NAME=""
NUKE="FALSE"
SSHINIT="FALSE"
SSLINIT="FALSE"
SSHRESET="FALSE"
SSLRESET="FALSE"
SSHDELETE="FALSE"
SSLDELETE="FALSE"                                        
                                         
usage() {                                      
  echo "Usage: ${0} -r -n NAME to reinitialise an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -c -n NAME to create an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -d -n NAME to delete an OpenSSH Certificate Authority" 1>&2
  echo "Usage: ${0} -R -n NAME to reinitialise an OpenSSL Certificate Authority" 1>&2
  echo "Usage: ${0} -C -n NAME to create an OpenSSL Certificate Authority" 1>&2
  echo "Usage: ${0} -D -n NAME to delete an OpenSSL Certificate Authority" 1>&2
  echo "Usage: ${0} -Z Nuke All Certificates!!!" 1>&2

}
exit_abnormal() {                              
  usage
  exit 1
}
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
      NUKE="TRUE"                         
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


exit 0                                         # Exit normally.