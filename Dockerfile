# Dockerfile official sonarqube docker image: https://github.com/SonarSource/docker-sonarqube/blob/master/7/community/Dockerfile
# FindBugs jar https://github.com/spotbugs/sonar-findbugs/releases/download/3.10.0/sonar-findbugs-plugin-3.10.0.jar

# update java version to 11 with sonarqube 7.9

FROM openjdk:11-jre-slim

RUN apt-get update \
    && apt-get install -y curl gnupg2 unzip \
    && rm -rf /var/lib/apt/lists/*

ENV SONAR_VERSION=7.9.3 \
    SONARQUBE_HOME=/opt/sonarqube \
    SONARQUBE_JDBC_USERNAME=sonar \
    SONARQUBE_JDBC_PASSWORD=sonar \
    SONARQUBE_JDBC_URL= \
	DPCHECK_JAR=https://github.com/dependency-check/dependency-check-sonar-plugin/releases/download/2.0.4/sonar-dependency-check-plugin-2.0.4.jar \
	FIND_BUGS_JAR=https://github.com/spotbugs/sonar-findbugs/releases/download/3.10.0/sonar-findbugs-plugin-3.10.0.jar

LABEL maintainer = "mauro.dev88@gmail.com

# Http port
EXPOSE 9000:9000

RUN groupadd -r sonarqube && useradd -r -g sonarqube sonarqube

# pub   2048R/D26468DE 2015-05-25
#       Key fingerprint = F118 2E81 C792 9289 21DB  CAB4 CFCA 4A29 D264 68DE
# uid                  sonarsource_deployer (Sonarsource Deployer) <infra@sonarsource.com>
# sub   2048R/06855C1D 2015-05-25
RUN for server in $(shuf -e ha.pool.sks-keyservers.net \
                            hkp://p80.pool.sks-keyservers.net:80 \
                            keyserver.ubuntu.com \
                            hkp://keyserver.ubuntu.com:80 \
                            pgp.mit.edu) ; do \
        gpg --batch --keyserver "$server" --recv-keys F1182E81C792928921DBCAB4CFCA4A29D26468DE && break || : ; \
    done

RUN set -x \
    && cd /opt \
    && curl -o sonarqube.zip -fSL https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip \
    && curl -o sonarqube.zip.asc -fSL https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip.asc \
    && gpg --batch --verify sonarqube.zip.asc sonarqube.zip \
    && unzip -q sonarqube.zip \
    && mv sonarqube-$SONAR_VERSION sonarqube \
    && chown -R sonarqube:sonarqube sonarqube \
    && rm sonarqube.zip* \
    && rm -rf $SONARQUBE_HOME/bin/* \
    # download and add Findbugs,OWASP dependency check
	&& curl -o findbugs.jar -fSL $FIND_BUGS_JAR \
    && mv findbugs.jar sonarqube/extensions/plugins \
	&& curl -o depcheck.jar -fSL $DPCHECK_JAR \
    && mv depcheck.jar sonarqube/extensions/plugins

VOLUME "$SONARQUBE_HOME/data"

WORKDIR $SONARQUBE_HOME
COPY run.sh $SONARQUBE_HOME/bin/
COPY quality.sh $SONARQUBE_HOME/bin/
USER sonarqube
ENTRYPOINT ./bin/run.sh
