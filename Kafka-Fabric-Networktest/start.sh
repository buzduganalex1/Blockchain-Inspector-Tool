#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -e
# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

## docker-compose -f ./network-config/docker-compose-kafka.yml down || echo "Docker - closing kafka nodes"
## docker-compose -f ./network-config/docker-compose-cli.yml down || echo "Docker - closing cli node"

## For closing the couchdb peers
## docker stop $(docker ps -aq) || echo "Docker - stopping couchDB nodes"
## docker rm $(docker ps -aq) || echo "Docker - removing couchDB nodes"

docker-compose -f ./network-config/docker-compose-kafka.yml -f ./network-config/docker-compose-couchdb.yml  up -d
docker-compose -f ./network-config/docker-compose-cli.yml up -d 

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>

# # # Create the channel on orderer 0 
passed="1"

while [ "$passed" -eq "1" ]
do 
    echo "Creating channel mychannel..."
    if docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp" -e "CORE_PEER_TLS_ROOTCERT_FILE=/var/hyperledger/users/Admin@org1.example.com/tls/ca.crt" -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" peer0.org1.example.com peer channel create -o orderer0.example.com:7050 -c mychannel -t 30s -f /var/hyperledger/configs/channel.tx ; then
        passed=0
        echo "Channel created."
    else
        echo "Waiting 30s..."    
        sleep 30
    fi
done
   

echo "Joining the channel..."

# # # Join peer0.org1.example.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp" -e "CORE_PEER_TLS_ROOTCERT_FILE=/var/hyperledger/users/Admin@org1.example.com/tls/ca.crt" -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" peer0.org1.example.com peer channel fetch config mychannel.block -c mychannel --orderer orderer0.example.com:7050
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp" -e "CORE_PEER_TLS_ROOTCERT_FILE=/var/hyperledger/users/Admin@org1.example.com/tls/ca.crt" -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" peer0.org1.example.com peer channel join -b mychannel.block

docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp" -e "CORE_PEER_TLS_ROOTCERT_FILE=/var/hyperledger/users/Admin@org1.example.com/tls/ca.crt" -e "CORE_PEER_ADDRESS=peer1.org1.example.com:7051" peer0.org1.example.com peer channel join -b mychannel.block
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org2.example.com/msp" -e "CORE_PEER_TLS_ROOTCERT_FILE=/var/hyperledger/users/Admin@org2.example.com/tls/ca.crt" -e "CORE_PEER_ADDRESS=peer0.org2.example.com:7051" peer0.org2.example.com peer channel fetch config mychannel.block -c mychannel --orderer orderer0.example.com:7050
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org2.example.com/msp" -e "CORE_PEER_TLS_ROOTCERT_FILE=/var/hyperledger/users/Admin@org2.example.com/tls/ca.crt" -e "CORE_PEER_ADDRESS=peer0.org2.example.com:7051" peer0.org2.example.com peer channel join -b mychannel.block
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org2.example.com/msp" -e "CORE_PEER_TLS_ROOTCERT_FILE=/var/hyperledger/users/Admin@org2.example.com/tls/ca.crt" -e "CORE_PEER_ADDRESS=peer1.org2.example.com:7051" peer0.org2.example.com peer channel join -b mychannel.block

echo "Installing chaincode..."
docker exec -it cli peer chaincode install -n sacc -p github.com/chaincode -v v0 || echo "Chaincode sacc not installed."

echo "Installing chaincode..."
docker exec -it cli peer chaincode instantiate -o orderer0.example.com:7050 -C mychannel -n sacc github.com/chaincode -v v0 -c '{"Args": ["a", "100"]}' || echo "Chaincode sacc not instantiated."

## peer channel fetch config mychannel.block -c mychannel --orderer orderer0.example.com:7050
## CORE_PEER_ADDRESS=peer0.org1.example.com:7051
## CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp
## CORE_PEER_LOCALMSPID=Org1MSP
## CORE_PEER_TLS_ROOTCERT_FILE=/var/hyperledger/users/Admin@org1.example.com/tls/ca.crt