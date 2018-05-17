#!/bin/bash

#The manager doesnt need to add the workers to the env because
#the localhost deploys the docker-compose.yaml
#in fact its never needed cause the docker-compose.yaml is copied
#to every node in the folder specified.
#if we want the manager to add to the env the workers, we need to
#install docker-machine in the managers with the following command:
#       docker-machine ssh manager$i "base=https://github.com/docker/machine/releases/download/v0.14.0 &&
#       curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine &&
#       sudo install /tmp/docker-machine /usr/local/bin/docker-machine"

if [ $# -ne 3 ]
then
	echo "Use: ./iotanet_gen.sh #NumOfStacks #NumOfWorkersPerManager DirFolderWithContents"
	exit 1
fi

for i in $(seq "$(($1))")
do
	#Managers creation
	docker-machine create --driver virtualbox manager$i

	#Get the last created manager's IP
	lastManagerIP=$(docker-machine ls | grep "manager$i" | awk '{print $5}')
	lastManagerIP=(`echo $lastManagerIP | sed -e 's/tcp:\/\//'/g`)
	lastManagerIP=(`echo $lastManagerIP | sed -e 's/:[0-9]*$/'/g`)

	#Managers Initialization
	token=$(docker-machine ssh manager$i "docker swarm init --advertise-addr $lastManagerIP" | grep -m1 docker)

	#Managers receive the Folder with the node's Software
	docker-machine scp -r $3 manager$i:/home/docker

	#Managers generate the image using the Dockerfile they received
	docker-machine ssh manager$i "docker build /home/docker/IOTA_node -t iotanode:lastest"

	#Localhost adds the Manager to the environment
	docker-machine env manager$i

	#Managers initialize the service
	docker-machine ssh manager$i "docker run --name managercont$i -p 14265:14265 -p 14600:14600/udp -p 15600:15600 iotanode:lastest > log_fich" &

	for j in $(seq "$(($2))")
	do
		#Workers creation
		docker-machine create --driver virtualbox worker$i-$j

		#Workers join the manager
		docker-machine ssh worker$i-$j "eval $token"

		#Workers receive the Folder with the node's Software
		docker-machine scp -r $3 worker"$i-$j":/home/docker

		#Workers generate the image using the Dockerfile they received
		docker-machine ssh worker$i-$j "docker build /home/docker/IOTA_node -t iotanode:lastest"

		#Localhost adds the workers to the environment
		#We will manage every node from the localhost.
		docker-machine env worker$i-$j

	done

	#Docker Stack deployment in the managers
	docker-machine ssh manager$i \
		"docker stack deploy --with-registry-auth -c /home/docker/IOTA_node/docker-compose.yml stack$i"
done

#Managers add other managers as neigbors.
managerIPs=(`docker-machine ls | awk '$1 ~ "manager" {print $5}'`)
for i in "${managerIPs[@]}"
do
        for j in "${managerIPs[@]}"
        do
                if [ $i != $j ]
                then
                        x=(`echo $i | sed -e 's/:[0-9]*$/:14265'/g`)
                        x=(`echo $x | sed -e 's/tcp/http'/g`)
                        y=(`echo $j | sed -e 's/:[0-9]*$/:15600'/g`)

                        cmd="curl $x
                                -X POST
                                -H 'X-IOTA-API-Version: 1'
                                -d '{\"command\": \"addNeighbors\", \"uris\": [\"$y\"]}'"

                        eval $cmd

                        echo "$x añade a $y"
                fi
        done
done
