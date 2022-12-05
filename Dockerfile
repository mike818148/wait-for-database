FROM ubuntu:22.04

# Arguments
ARG HOST
ENV HOST ${HOST}

ARG USER
ENV USER ${USER}

ARG PASSWORD
ENV PASSWORD ${PASSWORD}

ARG DATABASE
ENV DATABASE ${DATABASE}

ARG TYPE
ENV TYPE ${TYPE}

ARG INTERVAL
ENV INTERVAL ${INTERVAL}

ARG RETRIES
ENV RETRIES ${RETRIES}

# Install MySQL client
RUN apt-get update
RUN apt-get -y install wget curl unzip gnupg2 
RUN apt-get -y install mysql-client

# Install MSSQL client (sqlcmd)
ENV ACCEPT_EULA y
ENV DEBIAN_FRONTEND noninteractive 
RUN wget -qO - https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | tee /etc/apt/sources.list.d/msprod.list 
RUN apt-get update 
RUN apt-get -y install mssql-tools unixodbc-dev
ENV PATH $PATH:/opt/mssql-tools/bin

# Install Oracle client (sqlplus)
RUN apt-get -y install libaio1
RUN wget https://download.oracle.com/otn_software/linux/instantclient/218000/instantclient-basiclite-linux.x64-21.8.0.0.0dbru.zip
RUN wget https://download.oracle.com/otn_software/linux/instantclient/218000/instantclient-sqlplus-linux.x64-21.8.0.0.0dbru.zip
RUN mkdir -p /opt/oracle
RUN unzip -d /opt/oracle instantclient-basiclite-linux.x64-21.8.0.0.0dbru.zip
RUN rm -f instantclient-basiclite-linux.x64-21.8.0.0.0dbru.zip
RUN unzip -d /opt/oracle instantclient-sqlplus-linux.x64-21.8.0.0.0dbru.zip
RUN rm -f instantclient-sqlplus-linux.x64-21.8.0.0.0dbru.zip
ENV ORACLE_HOME /opt/oracle/instantclient_21_8
ENV LD_LIBRARY_PATH $ORACLE_HOME:$LD_LIBRARY_PATH
ENV PATH $LD_LIBRARY_PATH:$PATH

COPY ./check-oracle.sh /check-oracle.sh
RUN chmod +x /check-oracle.sh

COPY ./wait-for-database.sh /wait-for-database.sh
RUN chmod +x /wait-for-database.sh
ENTRYPOINT ["sh", "-c", "/wait-for-database.sh", "-h", "${HOST}", "-u", "${USER}", "-p", "${PASSWORD}", "-d", "${DATABASE}", "-t", "${TYPE}", "-i", "${INTERVAL}", "-r", "${RETRIES}"]
