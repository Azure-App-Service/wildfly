FROM mcr.microsoft.com/java/jre:8u181-zulu-alpine
LABEL maintainer="Azure App Services Container Images <appsvc-images@microsoft.com>"

ADD default.jar /tmp/webapps/default.jar
ADD init_container.sh /bin/init_container.sh
ADD sshd_config /etc/ssh/
ENV JAVA_OPTS=""
ENV _JAVA_OPTIONS -Djava.net.preferIPv4Stack=true
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV JAVA_VERSION 8u181
#
# Enable and conigure SSH:
#
RUN apk add --update openssh-server \
        && echo "root:Docker!" | chpasswd \
        && apk update && apk add openrc \
        && rm -rf /var/cache/apk/* \
        && chmod 755 /bin/init_container.sh \
        && apk add --no-cache bash; \
	    find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' +

EXPOSE 80 2222

ENTRYPOINT ["/bin/init_container.sh"]