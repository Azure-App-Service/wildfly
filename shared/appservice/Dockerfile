ARG BASE_IMAGE=__PLACEHOLDER_BASEIMAGE__
ARG GIT_COMMIT=unspecified
FROM $BASE_IMAGE

# Re-define ARG to make the build argument available for use in the rest of the Dockerfile
ARG GIT_COMMIT

LABEL maintainer="Azure App Services Container Images <appsvc-images@microsoft.com>"

ENV WILDFLY_VERSION __PLACEHOLDER_WILDFLY_VERSION__
ENV JBOSS_HOME /opt/jboss/wildfly
ENV GIT_COMMIT $GIT_COMMIT

ENV PORT 80
ENV SSH_PORT 2222

# WildFly configuration
COPY tmp/wildfly-$WILDFLY_VERSION.tar.gz /tmp/wildfly-$WILDFLY_VERSION.tar.gz
COPY tmp/shared/wildfly/__PLACEHOLDER_WILDFLY_MAJOR_VERSION__/standalone-full.xml /tmp/wildfly/standalone-full.xml

# miscellaneous configuration
COPY tmp/shared/appservice/init_container.sh /bin/init_container.sh
COPY tmp/shared/appservice/sshd_config /etc/ssh/
COPY tmp/shared/appservice/index.jsp /tmp/wildfly/webapps/ROOT/index.jsp

# azure.appservice.easyauth.jar configuration
COPY tmp/shared/appservice/lib/azure.appservice.easyauth.jar /tmp/wildfly/appservice/lib/azure.appservice.easyauth.jar
COPY tmp/shared/appservice/lib/azure.appservice.easyauth-module.xml /tmp/wildfly/appservice/lib/azure.appservice.easyauth-module.xml
COPY tmp/shared/appservice/lib/azure.appservice.easyauth.cli /tmp/wildfly/appservice/lib/azure.appservice.easyauth.cli

# azure.appservice.jar configuration
COPY tmp/shared/appservice/lib/azure.appservice.jar /tmp/wildfly/appservice/lib/azure.appservice.jar
COPY tmp/shared/appservice/lib/azure.appservice-module.xml /tmp/wildfly/appservice/lib/azure.appservice-module.xml
COPY tmp/shared/appservice/lib/azure.appservice.cli /tmp/wildfly/appservice/lib/azure.appservice.cli

RUN apk add --update openssh-server bash openrc \
        && rm -rf /var/cache/apk/* \
        # Remove unnecessary services
        && rm -f /etc/init.d/hwdrivers \
                 /etc/init.d/hwclock \
                 /etc/init.d/mtab \
                 /etc/init.d/bootmisc \
                 /etc/init.d/modules \
                 /etc/init.d/modules-load \
                 /etc/init.d/modloop \
        # Can't do cgroups
        && sed -i 's/\tcgroup_add_service/\t#cgroup_add_service/g' /lib/rc/sh/openrc-run.sh \
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
