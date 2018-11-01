ARG BASE_IMAGE=mcr.microsoft.com/java/jre:8u181-zulu-alpine
ARG WILDFLY_VERSION
FROM $BASE_IMAGE

# Redefine - as we need it inside the container
ARG WILDFLY_VERSION

LABEL maintainer="Azure App Services Container Images <appsvc-images@microsoft.com>"

ENV WILDFLY_VERSION $WILDFLY_VERSION
ENV JBOSS_HOME /opt/jboss/wildfly

ENV _JAVA_OPTIONS -Djava.net.preferIPv4Stack=true

ENV JAVA_OPTS -Djboss.http.port=80 $JAVA_OPTS
ENV JAVA_OPTS -Djboss.server.log.dir=/home/LogFiles $JAVA_OPTS

COPY init_container.sh /bin/init_container.sh
COPY sshd_config /etc/ssh/
COPY tmp/wildfly-$WILDFLY_VERSION.tar.gz /tmp/wildfly-$WILDFLY_VERSION.tar.gz

RUN apk add --update openssh-server bash openrc \
        && rm -rf /var/cache/apk/* \
        && echo "root:Docker!" | chpasswd \
        && tar xvzf /tmp/wildfly-$WILDFLY_VERSION.tar.gz -C /tmp \
        && chmod 755 /bin/init_container.sh \
        && mkdir -p `dirname $JBOSS_HOME` \
        && mv /tmp/wildfly-$WILDFLY_VERSION $JBOSS_HOME

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

EXPOSE 80 2222

ENTRYPOINT ["/bin/init_container.sh"]
