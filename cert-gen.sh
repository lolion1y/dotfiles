#! /bin/bash
# https://www.mingfer.cn/2020/06/13/altern-name
# https://foreverzmyer.hashnode.dev/https-ecc
# Please remove the line containing -subj before using

ca_cnf() {
cat > ./ca.openssl.cnf << EOF
# OpenSSL root CA configuration file.

[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = ./root
new_certs_dir     = \$dir
database          = \$dir/index.txt
serial            = \$dir/serial

private_key       = \$dir/ca.key.pem
certificate       = \$dir/ca.cert.pem

policy            = policy_match

[ policy_match ]
countryName             = match
stateOrProvinceName     = optional
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
distinguished_name  = req_distinguished_name
string_mask = utf8only
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:TRUE
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:TRUE, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOF
}

inter_ca_cnf() {
cat > ./interca.openssl.cnf << EOF
# OpenSSL Intermediate CA configuration file.

[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = ./intermediate
new_certs_dir     = \$dir
database          = \$dir/index.txt
serial            = \$dir/serial

private_key       = \$dir/intermediate.ca.key.pem
certificate       = \$dir/intermediate.ca.cert.pem

policy            = policy_match

[ policy_match ]
countryName             = match
stateOrProvinceName     = optional
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
distinguished_name  = req_distinguished_name
string_mask         = utf8only

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

[ server_cert ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
EOF
}

gen_ca() {
  echo "INFO: 生成 ca 证书"
  mkdir -p root
  ca_cnf
  openssl ecparam -genkey -name prime256v1 -out ./root/ca.key.pem
  openssl req -new -x509 \
    -config ./ca.openssl.cnf \
    -subj "/C=AQ/O=Loli Network Co./CN=LoliRootCA" \
    -key ./root/ca.key.pem \
    -out ./root/ca.cert.pem \
    -days 73000 \
    -extensions v3_ca
}

gen_inter_ca() {
  echo "INFO: 生成 intermediate ca 证书"
  mkdir -p intermediate
  inter_ca_cnf
  openssl ecparam -genkey -name prime256v1 -out ./intermediate/intermediate.ca.key.pem
  openssl req -new \
    -config ./interca.openssl.cnf \
    -subj "/C=AQ/O=Loli Network Co./CN=LoliIntermediateCA" \
    -key ./intermediate/intermediate.ca.key.pem \
    -out ./intermediate/intermediate.ca.csr.pem
  touch ./root/index.txt
  echo 1000 > ./root/serial
  openssl ca \
    -config ./ca.openssl.cnf \
    -in ./intermediate/intermediate.ca.csr.pem \
    -out ./intermediate/intermediate.ca.cert.pem \
    -md sha256 \
    -days 70000 \
    -extensions v3_intermediate_ca
}

ca_chain() {
  echo "INFO: 合并 ca 证书链"
  cat ./intermediate/intermediate.ca.cert.pem ./root/ca.cert.pem > ./root/ca-chain.cert.pem
}

gen_cert() {
  echo "INFO: 生成 server 证书"
  read -p "请输入证书文件名：" certname
  mkdir -p "$certname"
  read -p "请输入服务器IP（eg. IP:127.0.0.1,IP:198.18.0.1,DNS:example.org）：" server
  openssl ecparam -genkey -name prime256v1 -out ./"$certname"/"$certname".key.pem
  openssl req -new \
    -config ./interca.openssl.cnf \
    -subj "/C=AQ/O=Loli Network Co./CN=LoliCert" \
    -key ./"$certname"/"$certname".key.pem \
    -out ./"$certname"/"$certname".csr.pem \
    -addext "subjectAltName=$server"
  openssl x509 -req \
    -in ./"$certname"/"$certname".csr.pem \
    -out ./"$certname"/"$certname".cert.pem \
    -days 36500 \
    -copy_extensions copy \
    -CA ./intermediate/intermediate.ca.cert.pem \
    -CAkey ./intermediate/intermediate.ca.key.pem \
    -CAcreateserial
  echo "INFO: 合并证书链"
  cat ./intermediate/intermediate.ca.cert.pem >> ./"$certname"/"$certname".cert.pem
}

while (($# >= 1)); do
  case "$1" in
    *) $* ;;
  esac
  shift 1
done