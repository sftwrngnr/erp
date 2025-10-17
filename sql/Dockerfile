
FROM ubuntu:22.04 AS builder

USER root

# disable apt interaction
ENV DEBIAN_FRONTEND=noninteractive

# install and configure postgresql apt repository
RUN apt update && apt install -y postgresql-common gnupg && \
    /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -i -v 16

# install dependencies for building apache age against postgresql 16
RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests \
       bison \
       build-essential \
       flex \
       postgresql-server-dev-16 \
       ca-certificates \
       libc6 \
       git-core && \
    rm -rf /var/lib/apt/lists/*

RUN ldd --version

FROM builder AS apache_age

WORKDIR /tmp

ARG APACHE_AGE_VERSION=PG16/v1.5.0-rc0
RUN git clone -b ${APACHE_AGE_VERSION} https://github.com/apache/age.git

WORKDIR /tmp/age
RUN make clean && make PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config install

FROM builder AS pg_vector

WORKDIR /tmp

ARG PGVECTOR_VERSION=v0.8.0
RUN git clone -b ${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git

WORKDIR /tmp/pgvector
RUN make install

FROM ghcr.io/zalando/spilo-17:4.0-p2 as final

USER root 

COPY --from=apache_age /usr/lib/postgresql/16/lib/age.so /usr/lib/postgresql/16/lib/
COPY --from=apache_age /usr/share/postgresql/16/extension/age.control /usr/share/postgresql/16/extension/
COPY --from=apache_age /usr/share/postgresql/16/extension/age--*.sql /usr/share/postgresql/16/extension/

COPY --from=pg_vector /usr/lib/postgresql/16/lib/vector.so /usr/lib/postgresql/16/lib/
COPY --from=pg_vector /usr/share/postgresql/16/extension/vector.control /usr/share/postgresql/16/extension/
COPY --from=pg_vector /usr/share/postgresql/16/extension/vector--*.sql /usr/share/postgresql/16/extension/

USER postgres

CMD ["/bin/sh", "/launch.sh", "init"]
