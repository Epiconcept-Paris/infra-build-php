FROM debian:stretch

MAINTAINER Epiconcept

RUN echo "export TERM=xterm" >> /root/.bashrc
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ADD Dockerfile /

# update
RUN apt-get update
RUN apt-get upgrade -y

#outils [apache2-dev apache2]
RUN apt-get install -y --no-install-recommends vim autoconf curl file libjpeg62-turbo libpng16-16 libxml2 make pkg-config bzip2  libmcrypt-dev libmhash-dev libxslt1-dev libxpm-dev tar build-essential curl libbz2-dev libfreetype6-dev default-libmysqlclient-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libreadline6-dev libssl-dev libxml2-dev libxft-dev 

#librairies necessaires
RUN apt-get install -y --no-install-recommends patch libc-dev

#paquets pour build
RUN apt-get install -y --no-install-recommends fakeroot lintian dpkg-dev zip

RUN mkdir -p /opt/debbuild/usr
RUN mkdir /opt/output
ADD paquet /paquet
ADD scripts/* /

ADD docker-entrypoint.sh /
RUN chmod 0555 /docker-entrypoint.sh

CMD [ "/docker-entrypoint.sh" ]
