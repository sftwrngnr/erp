ARG AWS_ECR_REPO
ARG BASE_UBI9_VERSION
ARG GO_DOCKER_IMAGE

FROM $AWS_ECR_REPO/$GO_DOCKER_IMAGE AS buildbase

USER root

FROM buildbase AS migrate

WORKDIR /go/src
RUN git clone -b v4.18.3 --depth=1 https://github.com/golang-migrate/migrate.git \
    && cd migrate/cmd/migrate \
    && go get -u \
        google.golang.org/grpc@v1.73.0 \
    && go mod tidy \
    && CGO_ENABLED=0 go install -tags 'postgres'

FROM buildbase AS mc

WORKDIR /go/src
RUN git clone -b RELEASE.2025-05-21T01-59-54Z --depth=1 https://github.com/minio/mc.git \
    && cd mc \
    && go install -v -ldflags "$(go run buildscripts/gen-ldflags.go)"

FROM buildbase AS yq

WORKDIR /go/src
RUN git clone -b v4.45.4 --depth=1 https://github.com/mikefarah/yq.git \
    && cd yq \
    && go install

FROM buildbase AS vitproto

WORKDIR /build/util/vitproto
COPY services/lib ../../services/lib
COPY services/api ../../services/api

COPY util/vitproto .
RUN --mount=type=cache,uid=1001,target=/home/golanguser/.cache \
    --mount=type=cache,uid=1001,target=/go/pkg/mod \
    go install

FROM $AWS_ECR_REPO/base/ubi9:$BASE_UBI9_VERSION AS redis

USER root
RUN microdnf update -y --nodocs \
    && microdnf install -y \
        git-core \
        make \
        gcc \
        python3 \
    && microdnf clean all

WORKDIR /src
RUN git clone -b 7.4.2 --depth=1 https://github.com/redis/redis.git \
    && cd redis \
    && make redis-cli \
    && cp src/redis-cli /usr/bin/redis-cli

FROM $AWS_ECR_REPO/base/ubi9:$BASE_UBI9_VERSION AS tcpdump

USER root
RUN microdnf update -y --nodocs && \
    microdnf install -y \
        gcc \
        libpcap-devel \
        make \
        tar \
        wget \
        xz \
    && microdnf clean all

WORKDIR /src
RUN wget https://www.tcpdump.org/release/tcpdump-4.99.5.tar.xz \
    && tar -xf tcpdump-4.99.5.tar.xz \
    && cd tcpdump-4.99.5 \
    && ./configure --prefix=/opt/tcpdump \
    && make \
    && make install \
    && cd .. \
    && rm -rf tcpdump-4.99.5.tar.xz tcpdump-4.99.5

FROM $AWS_ECR_REPO/base/ubi9:$BASE_UBI9_VERSION

RUN curl -fsSLO https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm \
    && rpm -ivh pgdg-redhat-repo-latest.noarch.rpm \
    && microdnf install -y \
        bash-completion \
        bind-utils \
        findutils \
        iproute \
        iputils \
        jq \
        less \
        make \
        nc \
        nmap \
        openssh-clients \
        postgresql17 \
        procps-ng \
        python39 \
        python-pip \
        rsync \
        socat \
        strace \
        tar \
        unzip \
        vim-minimal \
        wget \
        zip \
    && rpm -e $(rpm -q pgdg-redhat-repo-latest.noarch.rpm) \
    && rm -f pgdg-redhat-repo-latest.noarch.rpm \
    && microdnf update -y --nodocs  \
    && microdnf clean all

RUN pip3 install --upgrade setuptools==78.1.1

COPY services/toolbox/mcwrapper.sh /usr/bin/mc
COPY services/toolbox/aliases.sh /etc/profile.d/aliases.sh

COPY --from=migrate /go/bin/migrate /usr/bin/migrate
COPY --from=mc /go/bin/mc /usr/bin/.mc
COPY --from=yq /go/bin/yq /usr/bin/yq
COPY --from=redis /usr/bin/redis-cli /usr/bin/redis-cli
COPY --from=tcpdump /opt/tcpdump/bin/tcpdump /usr/local/bin/tcpdump

COPY --from=vitproto /go/bin/vitproto /usr/local/bin/vitproto
RUN echo 'source <(vitproto completion bash)' >/etc/profile.d/vitproto_completion.sh

# Create common users
RUN echo kyverno:x:5000:5000:kyverno:/home/kyverno:/bin/bash >>/etc/passwd \
    && echo nonroot:x:65532:65532:nonroot:/home/nonroot:/bin/bash >>/etc/passwd \
    && cp -r /etc/skel /home/kyverno \
    && cp -r /etc/skel /home/nonroot \
    && chown -R kyverno /home/kyverno \
    && chown -R nonroot /home/nonroot

RUN update-crypto-policies --set DEFAULT:NO-ENFORCE-EMS

HEALTHCHECK NONE

ENTRYPOINT ["/bin/bash"]
CMD ["-l"]
