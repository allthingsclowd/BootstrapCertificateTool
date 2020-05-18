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

LetsEncrypt Public Certs

```

bash

root@cert-server01:/usr/local/bootstrap/scripts# DOMAIN=hashistack.ie
root@cert-server01:/usr/local/bootstrap/scripts#     certbot certonly --manual \
>                     -d *.$DOMAIN -d $DOMAIN \
>                     --agree-tos \
>                     --manual-public-ip-logging-ok \
>                     --preferred-challenges dns-01 \
>                     --server https://acme-v02.api.letsencrypt.org/directory \
>                     --register-unsafely-without-email \
>                     --rsa-key-size 4096 \
>                     --keep-until-expiring
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator manual, Installer None
Registering without email!
Obtaining a new certificate
Performing the following challenges:
dns-01 challenge for hashistack.ie
dns-01 challenge for hashistack.ie

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name
_acme-challenge.hashistack.ie with the following value:

J59ujD8DqZ23ams4HPKLgD7Nsps-Cdk9qaCWw2ADVLY

Before continuing, verify the record is deployed.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name
_acme-challenge.hashistack.ie with the following value:

IRBMYtkqQnUHGr394sPWhHsh6mFVO4pv0cYjIqi-uag

Before continuing, verify the record is deployed.
(This must be set up in addition to the previous challenges; do not remove,
replace, or undo the previous challenge tasks yet. Note that you might be
asked to create multiple distinct TXT records with the same name. This is
permitted by DNS standards.)

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/hashistack.ie/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/hashistack.ie/privkey.pem
   Your cert will expire on 2020-08-16. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - Your account credentials have been saved in your Certbot
   configuration directory at /etc/letsencrypt. You should make a
   secure backup of this folder now. This configuration directory will
   also contain certificates and private keys obtained by Certbot so
   making regular backups of this folder is ideal.
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le


root@cert-server01:/usr/local/bootstrap/scripts# sudo cp -r /etc/letsencrypt /usr/local/bootstrap/PublicCerts_Protect/etc/.
```

