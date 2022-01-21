FROM debian:jessie
MAINTAINER Epiconcept

ENV DEBVER=jessie
ENV DEBNUM=8
ENV USER=cedric
ENV LANG=C
ENV TZ=Europe/Paris
RUN groupadd -g 1000 cedric; useradd -u 1000 -g 1000 cedric
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
RUN echo "export TERM=xterm\nalias l='ls -Al'\necho \"Use: /opt/tools/build\\nto build the packages\"" >>/root/.bashrc

# Update/upgrade, install tools and tools deps
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends vim file gcc libc-dev make fakeroot lintian manpages-dev

RUN mkdir -p /opt/tools/pkgs /opt/tools/dist
COPY pkgs /opt/tools/pkgs
COPY run/build /opt/tools/build

CMD [ "/opt/tools/build" ]
