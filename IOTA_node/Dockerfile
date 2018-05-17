FROM openjdk:jre-slim
MAINTAINER Anja
COPY iri.jar /iri.jar
COPY iota-testnet-tools-0.1-SNAPSHOT-jar-with-dependencies.jar /iota-testnet-tools-0.1-SNAPSHOT-jar-with-dependencies.jar
EXPOSE 14265
EXPOSE 14600/udp
EXPOSE 15600
CMD ["/usr/bin/java", "-XX:+DisableAttachMechanism", "-Xmx8g", "-Xms256m", "-Dlogback.configurationFile=/iri/conf/logback.xml", "-Djava.net.preferIPv4Stack=true", "-jar", "iri.jar", "-p", "14265", "-u", "14600", "-t", "15600", "--remote", "$@", "--testnet"]
