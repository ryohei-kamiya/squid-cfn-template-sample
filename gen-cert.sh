#!/bin/bash

openssl genrsa 2048 > ./etc/squid/proxy-bump.key

# You are about to be asked to enter information that will be incorporated
# into your certificate request.
# What you are about to enter is what is called a Distinguished Name or a DN.
# There are quite a few fields but you can leave some blank
# For some fields there will be a default value,
# If you enter '.', the field will be left blank.
# -----
# Country Name (2 letter code) []:JP
# State or Province Name (full name) []:Tokyo
# Locality Name (eg, city) []:Minato-ku
# Organization Name (eg, company) []:Dummy
# Organizational Unit Name (eg, section) []:Dummy
# Common Name (eg, fully qualified host name) []:${DOMAIN_NAME}
# Email Address []:

# Please enter the following 'extra' attributes
# to be sent with your certificate request
# A challenge password []:

openssl req -new -key ./etc/squid/proxy-bump.key <<EOF > ./etc/squid/proxy-bump.csr
JP
Tokyo
Minato-ku
Dummy
Dummy
${DOMAIN_NAME}



EOF
openssl x509 -days 3650 -req -signkey ./etc/squid/proxy-bump.key < ./etc/squid/proxy-bump.csr > ./etc/squid/proxy-bump.crt
