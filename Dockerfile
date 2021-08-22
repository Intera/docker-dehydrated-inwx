FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

RUN apt-get update
RUN apt-get -y dist-upgrade
RUN apt-get -y install libxml2-utils openssl curl

RUN apt-get --purge -y autoremove \
	&& apt-get autoclean \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY files/download_dehydrated.sh /root/download_dehyrated.sh
RUN bash /root/download_dehyrated.sh
RUN rm /root/download_dehyrated.sh

COPY files/config.sh /opt/dehydrated/config
COPY files/dehydrated_hook.sh /opt/dehydrated/dehydrated_hook.sh
COPY files/dehydrated_runner.sh /opt/dehydrated/dehydrated_runner.sh

COPY files/inwx/inwx_acme_hook.sh /opt/dehydrated/inwx_acme_hook.sh
COPY files/inwx/inwx_hook_runner.sh /opt/dehydrated/inwx_hook_runner.sh
COPY files/inwx/inwx-acme.auth.sh /opt/dehydrated/inwx-acme.auth

RUN chmod +x "/opt/dehydrated/dehydrated_hook.sh"
RUN chmod +x "/opt/dehydrated/dehydrated_runner.sh"

RUN chmod +x "/opt/dehydrated/inwx_acme_hook.sh"
RUN chmod +x "/opt/dehydrated/inwx_hook_runner.sh"

RUN mkdir -p /var/www/dehydrated

CMD ["/opt/dehydrated/dehydrated_runner.sh"]
