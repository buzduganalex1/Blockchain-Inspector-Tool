 #!/bin/bash

set -e
RANGE=500

for i in `seq 1 6`;
do
    number=$RANDOM
    let "number %= $RANGE"
    echo "Random number less than $RANGE  ---  $number"
    arguments='{"Args":["set", "Asset-'"$number"'", "'"$number"'"]}'
    echo $arguments
    docker exec -it cli peer chaincode invoke -o orderer0.example.com:7050 -n sacc -c "$arguments" -C mychannel
done   
 