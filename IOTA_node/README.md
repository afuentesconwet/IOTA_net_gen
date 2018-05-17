# Set up your own private network IOTA

The following steps will explain how to run your own node, for a private network, locally and how to run it in as an AWS ec2-instance.

Note: We have used ubuntu for this project and have run into some issues while using a windows machine.

## **Prerequisites:**
You can download the IOTA wallet, with which you can easily perform a transaction, from https://github.com/iotaledger/wallet/releases.

Make sure the wallet does not connect to the real tangle but to your own one. You can do this in tools -> edit node configuration and then entering either your localhost or the url for your AWS EC2. Please note that you should use http:// when connecting to AWS.

## Local tangle

1) Clone the iri from the IOTA foundation (we used with v1.4.1.6)

        $ git clone https://github.com/iotaledger/iri.git

2) In the IRI comment out the 'check snapshot signature' part in src/main/java/com/iota/iri/snapshot.java (lines 50-82).

3) Create a snapshot and put it in your root, you can copy the one from this project or create your own. If you'd like to create your own snapshot see https://github.com/schierlm/private-iota-testnet.


4) Build the iri.

        $ cd iri
        $ mvn clean compile
        $ mvn package

5) Move the iri-1.4.1.6.jar from the target folder to the node folder (if you do not have a node folder, you can just create a new folder)

6) Run the node. In this example we have used port 14265, but you can use any port you like.

        $ cd node
        $ java -jar iri-1.4.1.6.jar -p 14265 --testnet

7)  If everything went according to plan you should be able to test if the node is running by making a POST call with curl or postman
 
        $ curl -H "X-IOTA-API-Version: 1.4.1.6" -X POST -d '{"command":"getNodeInfo"}' http://localhost:14265
        
    You should see:

        {
        "appName": "IRI",
        "appVersion": "1.4.1.6",
        "jreAvailableProcessors": 1,
        "jreFreeMemory": 160628072,
        "jreVersion": "1.8.0_151",
        "jreMaxMemory": 8303607808,
        "jreTotalMemory": 259522560,
        "latestMilestone": "999999999999999999999999999999999999999999999999999999999999999999999999999999999",
        "latestMilestoneIndex": 243000,
        "latestSolidSubtangleMilestone": "999999999999999999999999999999999999999999999999999999999999999999999999999999999",
        "latestSolidSubtangleMilestoneIndex": 243000,
        "neighbors": 0,
        "packetsQueueSize": 0,
        "time": 1516205078378,
        "tips": 0,
        "transactionsToRequest": 0,
        "duration": 27
        }

**Before you can perform a transaction the coordinator has to create a new milestone.**

8) Copy iota-testnet-tools-0.1-SNAPSHOT-jar-with-dependencies.jar from this project to the root of your own project and run in a new command line window from the root of your project

        $ java -jar iota-testnet-tools-0.1-SNAPSHOT-jar-with-dependencies.jar Coordinator localhost 14265

9) Now you are ready to perform a transaction with the IOTA Wallet! Pick an address you would like to sent money to and a seed from which you would like to sent the money from your snapshot.

    Note: Don't forget to change the url in the node configurations.

## Local tangle with docker

1) Clone the iri from the IOTA foundation (we used v1.4.1.6)

        $ git clone https://github.com/iotaledger/iri.git

2) In the IRI comment out the 'check snapshot signature' part in src/main/java/com/iota/iri/snapshot.java (lines 50-82).

3) Create a snapshot and put it in your root, you can copy the one from this project or create your own. If you'd like to create your own snapshot see https://github.com/schierlm/private-iota-testnet.


4) Build the iri.

        $ cd iri
        $ mvn clean compile
        $ mvn package

5) Move the iri-1.4.1.6.jar from the target folder to the node folder (if you do not have a node folder, you can just create a new folder)

6) Copy the Dockerfile from this project to the node folder of your own project and build the dockerfile

        $ cd ../node
        $ sudo docker build . -t iotanode:lastest

7) Run the dockerfile.

        $ sudo docker run --net=host -p 14265:14265 -p 14777:14777/udp -p 15777:15777 iotanode:latest

8) If everything went according to plan you should be able to test if the node is running by making a POST call with curl or postman
 
        $ curl -H "X-IOTA-API-Version: 1.4.1.6" -X POST -d '{"command":"getNodeInfo"}' http://localhost:14265

Before you can perform a transaction the coordinator has to create a new milestone.

9) Copy iota-testnet-tools-0.1-SNAPSHOT-jar-with-dependencies.jar from this project to the root of your own project and run in a new command line window from the root of your project

        $ java -jar iota-testnet-tools-0.1-SNAPSHOT-jar-with-dependencies.jar Coordinator localhost 14265

10) Now you are ready to perform a transaction with the IOTA Wallet! Pick an address you would like to sent money to and a seed from which you would like to sent the money from your snapshot.

    Note: Don't forget to change the url in the node configurations.

### Private tangle in ec2-instance in AWS

1) Clone the iri from the IOTA foundation (we used v1.4.1.6)

        $ git clone https://github.com/iotaledger/iri.git

2) In the IRI comment out the 'check snapshot signature' part in src/main/java/com/iota/iri/snapshot.java (lines 50-82).

3) Create a snapshot and put it in your root, you can copy the one from this project or create your own. If you'd like to create your own snapshot see https://github.com/schierlm/private-iota-testnet.


4) Build the iri.

        $ cd iri
        $ mvn clean compile
        $ mvn package

5) Move the iri-1.4.1.6.jar from the target folder to the node folder (if you do not have a node folder, you can just create a new folder)

6) Login to ECR and push to repository (the below commands are with the name/region that we used, ofcourse you can use your own)
        $ aws ecr get-login --no-include-email --region eu-west-1
        $ run the command of the result of above command
        $ sudo docker build -t iota .
        $ sudo docker tag iota:latest 588116866840.dkr.ecr.eu-west-1.amazonaws.com/iota-pow-3:latest
        $ sudo docker push 588116866840.dkr.ecr.eu-west-1.amazonaws.com/iota-pow-3:latest

7) Setup a new cluster in AWS ECS
        - Fill in a cluster name
        - Choose EC2 instance type
        - Choose key-pair, VPC, subnet, Security group
        - Leave the rest default

8) Create a task to spin up the EC2
        - Fill in a task name
        - Add container
        - Fill in container name
        - fill in repository url
        - Soft memory limit 3000
        - port mappings 80 14265 tcp 14777 14777 udp 15777 15777 tcp
        - cpu units 2
        - Leave the rest default

9) Create a service in the cluster
        - Task definition: the task you just created
        - Fill in service name
        - Number of tasks 1
        - Leave the rest default

10) If everything went according to plan you should be able to test if the node is running by making a POST call with curl or postman
 
        $ curl -H "X-IOTA-API-Version: 1.4.1.6" -X POST -d '{"command":"getNodeInfo"}' <<your ec2-instance url>>

11) Run the coordinator

        $ java -jar iota-testnet-tools-0.1-SNAPSHOT-jar-with-dependencies.jar Coordinator <<your ec2-instance url>> 80

12) Now you are ready to perform a transaction with the IOTA Wallet! Pick an address you would like to sent money to and a seed from which you would like to sent the money from your snapshot.

    Note: Don't forget to change the url in the node configurations.