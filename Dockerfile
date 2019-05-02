FROM openjdk:8-jre-slim

MAINTAINER Timo Pagel <dependencycheckmaintainer@timo-pagel.de>

ENV user=dependencycheck
ENV download_url=https://dl.bintray.com/jeremy-long/owasp
ENV version=4.0.2
ENV nist_data_mirror_version=1.2.0
ENV nist_data_mirror_download_url=https://github.com/stevespringett/nist-data-mirror/releases/download
RUN apt-get update                                                          && \
    apt-get install -y --no-install-recommends wget ruby mono-runtime       && \
    gem install bundle-audit                                                && \
    gem cleanup

RUN file="dependency-check-${version}-release.zip"                          && \
    wget "$download_url/$file"                                              && \
    unzip ${file}                                                           && \
    rm ${file}                                                              && \
    mv dependency-check /usr/share/                                         && \
    mkdir /report                                                           && \
    apt-get install sudo -y                                                 && \    
    apt-get install curl -y                                                 && \
    apt-get autoremove -y                                                   && \
    curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -          && \
    apt-get install build-essential nodejs -y                               && \
    apt-get install git -y                                                  && \
    rm -rf /var/lib/apt/lists/* /tmp/*                                      && \
    openssl s_client -showcerts -connect nvd.nist.gov:443 </dev/null 2>/dev/null|openssl x509 -outform DER -out nvd.nist.gov.cer && \
    echo "$JAVA_HOME"                                                       && \
    ls -l $JAVA_HOME/lib/security/cacerts                                   && \
    keytool -importcert -file nvd.nist.gov.cer -alias nvd -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -keypass changeit -noprompt && \
    export MAVEN_OPTS="-Djavax.net.ssl.keyStore=$JAVA_HOME/lib/security/cacert -Djavax.net.ssl.keyStorePassword=changeit -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Ddownloader.quick.query.timestamp=false" && \
    file="nist-data-mirror-${nist_data_mirror_version}/nist-data-mirror-${nist_data_mirror_version}.jar" && \
    wget ${nist_data_mirror_download_url}/${file}                           && \
    mkdir /usr/share/dependency-check/nist_data-mirror                      && \
    java -jar ./nist-data-mirror-1.2.0.jar /usr/share/dependency-check/nist_data-mirror/1.0 json && \ 
    /usr/share/dependency-check/bin/dependency-check.sh --updateonly --cveUrlBase=/usr/share/dependency-check/nist_data-mirror/1.0/nvdcve-1.0-%d.json.gz --cveUrlModified=/usr/share/dependency-check/nist_data-mirror/1.0/nvdcve-1.0-modified.json.gz && \
    apt-get remove --purge -y wget                                         && \
    apt-get remove --purge -y curl                                         && \
    apt-get remove --purge -y sudo                                         && \
    apt-get autoremove -y                                                  
 
VOLUME ["/src" "/usr/share/dependency-check/data" "/report"]

WORKDIR /src

CMD ["--help"]
ENTRYPOINT ["/usr/share/dependency-check/bin/dependency-check.sh"]
