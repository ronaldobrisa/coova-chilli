FROM debian:buster AS build

RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/buster-updates/d' /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    iptables iproute2 libssl1.1 git make gcc g++ libc-dev ca-certificates wget tar autoconf automake libtool pkg-config gengetopt patch && \
    update-ca-certificates && \
    git clone https://github.com/ncopa/su-exec.git /tmp/su-exec && \
    make -C /tmp/su-exec && \
    mv /tmp/su-exec/su-exec /usr/local/bin/su-exec && \
    chmod +x /usr/local/bin/su-exec && \
    rm -rf /tmp/su-exec && \
    rm -rf /var/lib/apt/lists/*


WORKDIR /usr/src

RUN wget https://github.com/coova/coova-chilli/archive/1.3.1.4.tar.gz && \
    tar xzf 1.3.1.4.tar.gz && \
    cd coova-chilli-1.3.1.4 && \
    sed -i "s/-Werror//g" configure.ac && \
    ./bootstrap && \
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var && \
    sed -i 's/-Werror//g' src/Makefile && \
    make && \
    make install DESTDIR=/tmp/install && \
    apt-get purge -y git make gcc g++ libc-dev autoconf automake libtool pkg-config gengetopt && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

FROM debian:buster-slim

RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/buster-updates/d' /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    iptables iproute2 libssl1.1 && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r chilli && useradd -r -g chilli chilli

COPY --from=build /tmp/install/ / 

COPY --from=build /usr/local/bin/su-exec /usr/local/bin/su-exec

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV HS_WANIF=eth0 \
    HS_LANIF=eth1

EXPOSE 3990

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["chilli", "--fg"]
