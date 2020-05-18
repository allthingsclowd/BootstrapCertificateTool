[![Build Status](https://travis-ci.org/allthingsclowd/BootstrapCertificateTool.svg?branch=master)](https://travis-ci.org/allthingsclowd/BootstrapCertificateTool)

# Self-Signed Certificate Generation

This repo stores the scripts and process that I currently use to generate the ephemeral certificates to bootstrap my demo environment. Don't get excited to think you've found a valuable CA on Github :) [Note to self, try to remember not to use these CAs for non demo environments...doh!]

I use the certificates to illustrate how to secure and continue to work with HashiCorp's tools namely Consul, Vault and Nomad.

The best place to find all [Official HashiCorp Training Material is here](https://learn.hashicorp.com/)!

# Caution :
I am NOT a PKI guru or have ANY Qualifications what-so-ever in the certificate security space. Do not use any of these examples near production without first getting inputs from a security subject matter expert.

With the disclaimer out of the way I use these certificates to facilitate illustrating how one can work with the HashiCorp products when they have TLS enabled.

Most online examples tend to default to HTTP only for brevity and clarity and assume adding TLS is trivial....I never find adding TLS trivial without access to a Subject Matter Expert :)

If you're curious about the bias in any of my blogs, repos, tweets, etc - I work for HashiCorp as a Customer Success Manager in EMEA - yes I'm biased!

## Prerequisites

Configure the certificate profiles and node configuration file to align with the target environment.

In my case that involves adding my details to the ca-config file. 

The script is idempotent(ish), let me explain - 
When `Generate_PKI_Certificates_For_Lab.sh` is excuted it checks to see if the Intermediate Certificate for the required application exists (it looks in the Outputs\IntermediateCAs\<application\application-intermediate-ca.pem> ).
If the file exists it moves on to creating the leaf certificates - this is to save me reloading these CAs into my browser again and again...
The same applies for the Root CA when the script is creating the Intermediate CA - it checks for Root CA existance and will create a new one if it's not there.

The script is run
