ARG BASE_IMAGE=__PLACEHOLDER_BASEIMAGE__
ARG WILDFLY_VERSION
FROM $BASE_IMAGE

# Redefine - as we need it inside the container
ARG WILDFLY_VERSION

LABEL maintainer="Azure App Services Container Images <appsvc-images@microsoft.com>"

ENV WILDFLY_VERSION __PLACEHOLDER_WILDFLY_VERSION__
ENV JBOSS_HOME /opt/jboss/wildfly

ENV _JAVA_OPTIONS -Djava.net.preferIPv4Stack=true

ENV JAVA_OPTS -Djboss.http.port=80 $JAVA_OPTS
ENV JAVA_OPTS -Djboss.server.log.dir=/home/LogFiles $JAVA_OPTS

COPY tmp/shared/misc/init_container.sh /bin/init_container.sh
COPY tmp/shared/wildfly/__PLACEHOLDER_WILDFLY_MAJOR_VERSION__/standalone-full.xml /tmp/wildfly/standalone-full.xml
COPY tmp/shared/misc/sshd_config /etc/ssh/
COPY tmp/wildfly-$WILDFLY_VERSION.tar.gz /tmp/wildfly-$WILDFLY_VERSION.tar.gz

COPY tmp/shared/misc/index.jsp /tmp/wildfly/webapps/ROOT/index.jsp
COPY tmp/shared/misc/background.png /tmp/wildfly/webapps/ROOT/background.png

RUN apk add --update openssh-server bash openrc \
        && rm -rf /var/cache/apk/* \
        && mkdir /root/.postgresql \
        && wget -O /root/.postgresql/root.crt https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt \
        && echo "root:Docker!" | chpasswd \
        && tar xvzf /tmp/wildfly-$WILDFLY_VERSION.tar.gz -C /tmp \
        && chmod 755 /bin/init_container.sh \
        && mkdir -p `dirname $JBOSS_HOME` \
        && mv /tmp/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
        && mv /tmp/wildfly/standalone-full.xml $JBOSS_HOME/standalone/configuration/standalone-full.xml

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

EXPOSE 80 2222

ENTRYPOINT ["/bin/init_container.sh"]
