FROM debian:9
MAINTAINER cedric@epiconcept.fr

ENV APTAUTH=$APTAUTH
ENV TZ=Europe/Paris
ENV PKGUTILS="vim tree mysql-client apt-transport-https curl gnupg ca-certificates file apache2"
ENV PKGEPI="epi-tous epiconcept-arborescence epi-frontal"
ENV PKGPHP="epi-php-5.6-fpm epi-php-7.1-fpm epi-php-7.3-fpm"

RUN echo $APTAUTH

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
RUN echo "export TERM=xterm\nalias l='ls -Al'\necho \"Use:\n    $BUILD_TOP/build\\nto start the build\"" >>/root/.bashrc

RUN apt-get update && apt-get upgrade -y && \
	apt-get install -y --no-install-recommends $PKGUTILS 
RUN curl https://$APTAUTH@apt.epiconcept.fr/prep/key.gpg > /tmp/key && apt-key add /tmp/key && \
	echo "deb [arch=amd64,all] https://$APTAUTH@apt.epiconcept.fr/prep/ stretch main" > /etc/apt/sources.list.d/epiconcept.list && \
	apt-get update 
RUN apt-get install -y --no-install-recommends $PKGEPI && \
	apt-get install -y --no-install-recommends $PKGPHP && \
	apt-get clean -y && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
	
#TODO CMD [ "$BUILD_TOP/build" ]