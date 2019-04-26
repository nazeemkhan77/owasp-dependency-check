FROM openjdk:8-jre-slim

MAINTAINER Timo Pagel <dependencycheckmaintainer@timo-pagel.de>

ENV user=dependencycheck
ENV download_url=https://dl.bintray.com/jeremy-long/owasp
ENV version=4.0.2
RUN apt-get update                                                          && \
    apt-get install -y --no-install-recommends wget ruby mono-runtime       && \
    gem install bundle-audit                                                && \
    gem cleanup

RUN file="dependency-check-${version}-release.zip"                          && \
    wget "$download_url/$file"                                              && \
    unzip ${file}                                                           && \
    rm ${file}                                                              && \
    mv dependency-check /usr/share/                                         && \
    useradd -ms /bin/bash ${user}                                           && \
	usermod -aG sudo ${user}                                           		&& \
    chown -R ${user}:${user} /usr/share/dependency-check                    && \
    mkdir /report                                                           && \
    chown -R ${user}:${user} /report                                        && \
    apt-get remove --purge -y wget                                          && \
    apt-get autoremove -y                                                   && \
    rm -rf /var/lib/apt/lists/* /tmp/*
 
USER ${user}

VOLUME ["/src" "/usr/share/dependency-check/data" "/report"]

WORKDIR /src

CMD ["--help"]
ENTRYPOINT ["/usr/share/dependency-check/bin/dependency-check.sh"]