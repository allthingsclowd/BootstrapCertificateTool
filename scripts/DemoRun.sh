#!/usr/bin/env bash

./Generate_PKI_Certificates_For_Lab.sh consul "server.node.global.consul" "client.node.global.consul" "1.2.3.4"
./Generate_PKI_Certificates_For_Lab.sh nomad "server.global.nomad" "client.global.nomad" "1.2.3.4"
./Generate_PKI_Certificates_For_Lab.sh vault "server.global.vault" "client.global.vault" "1.2.3.4"