#!/bin/bash
#This is a script that can be used to automate the renewal of Let's Encrypt SSL certificate when the Let's Encrypt plugin is not installed in cPanel by the hosting provider.
#Author : Leegin Bernads T.S
#Referred quite a few articles to get this done.Hope this works.

PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bon:/root/bin

#Get the user details of the cPanel account.
/scripts/whoowns domain.com
User=$(/scripts/whoowns)

# Lets create a folder under which we can place all the required files. I am going to name this folder as "letsacme".

mkdir /home/$User/letsacme
chown $User:$User /home/$User/letsacme
chmod 700 /home/$User/letsacme #Stripping of the permission of group and others for security reasons/
cd /home/$User/letsacme


# Now we can downlaod the letsacme script. This script automates the process of getting a signed TLS/SSL certificate from Let's Encrypt using the ACME protocol. We are going to download this from a git repository.

wget https://raw.githubusercontent.com/neurobin/letsacme/release/letsacme.py

# Then create an account key which can be used for any number of certificates that we are going to generate.

openssl genrsa 4096 > account.key

# We use a script named "gencsr" for generating the CSR everytime the certificate is renewed which is also downloaded from the git repo.

wget https://raw.githubusercontent.com/neurobin/gencsr/release/gencsr
wget https://raw.githubusercontent.com/neurobin/gencsr/release/gencsr.conf
chmod +x gencsr

# Have a list of domains for which the Let's encrypt certificate has to be renewed both www and non-www version of the sites. I am naming this file "dom.list".Put the non-www version of the root domain at the top.

touch dom.list
read -p "Enter the number of domains for which you want to renew the SSL certificate:" num
echo "The total number of domains to be renewed under your account is $num"
echo "Enter the domain names :"
while read domain
do
echo $domain >> dom.list
done

# Edit the file gencsr.conf with the required  details to generate CSR

./gencsr        #This will generate a file named "dom.csr"

# Then we download the SSL certificate using the script "sslic" which is a PHP script to install SSL certificate using UAPI (Cpanel API).

wget https://github.com/neurobin/sslic/raw/release/sslic.php

# Now we run the renew script. Make sure to set the permission to 600 since the script contains the cPanel user name and password.

chmod 600 renewcert.sh

