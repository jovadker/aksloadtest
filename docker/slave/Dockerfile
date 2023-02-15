FROM openjdk:8-jdk-slim
		
ARG JMETER_VERSION=5.2.1
		
RUN apt-get clean && \
apt-get update && \
apt-get -qy install \
wget \
unzip

RUN   mkdir /jmeter \
&& cd /jmeter/ \
&& wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz \
&& tar -xzf apache-jmeter-$JMETER_VERSION.tgz \
&& rm apache-jmeter-$JMETER_VERSION.tgz

#install Application Insghts listener
RUN cd jmeter/apache-jmeter-${JMETER_VERSION}/lib/ext/\
&& wget https://github.com/adrianmo/jmeter-backend-azure/releases/download/0.2.3/jmeter.backendlistener.azure-0.2.3.jar


ENV JMETER_HOME /jmeter/apache-jmeter-$JMETER_VERSION/
		
ENV PATH $JMETER_HOME/bin:$PATH

ENTRYPOINT $JMETER_HOME/bin/jmeter-server \
-Dserver.rmi.localport=50000 \
-Dserver_port=1099 \
-Jserver.rmi.ssl.disable=true