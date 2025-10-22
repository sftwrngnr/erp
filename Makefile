SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Docker build settings
export DOCKER_BUILDKIT = 1
export BUILDKIT_PROGRESS = plain

# Generic args
IMAGE_TAG_PREFIX ?=
IMAGE_TAG_SUFFIX ?=
IMAGE_TAG = $(IMAGE_TAG_PREFIX)erp/$@$(IMAGE_TAG_SUFFIX)
BASE_IMAGE_TAG = $(IMAGE_TAG_PREFIX)$@$(IMAGE_TAG_SUFFIX)
BUILD_CMD ?= docker build
BUILD_COMPOSE ?= docker compose

k3d-cluster: K3D_STORAGE_DIR ?= $(HOME)


spilo:
	$(BUILD_CMD) -t docker.io/sftwrngnr/erp:latest -f docker/sql/Dockerfile docker/sql
	docker tag docker.io/sftwrngnr/erp:latest docker.io/sftwrngnr/erp:latest
	docker push docker.io/sftwrngnr/erp:latest

hashicorp_vault:
	sudo rm -rf /var/services/vault/
	sudo mkdir -p /var/services/vault/{audit,config,data,file,logs,userconfig/tls,plugins}
	sudo chown -R 100:100 /var/services/vault/
	sudo cp docker/vault/docker-compose.yml /var/services
	sudo cp docker/vault/vault-config.hcl /var/services/vault/config/vault-config.hcl
	$(BUILD_COMPOSE) -f /var/services/docker-compose.yml up -d

#AWS_ECR_REPO ?= "325273307126.dkr.ecr.us-east-1.amazonaws.com"
UID = $(shell id -u)
GID = $(shell id -g)

# Image tags for base images built by us.
# Update after the pipeline rebuilding them finishes.
BASE_TESTDB_VERSION = 2025.01.02
BASE_UBI9_VERSION = 2025.10.13
BASE_RECORD_BUILD_VERSION = 2025.10.13
BASE_RECORD_RUN_VERSION = 2025.10.13
BASE_LIBZMQ_VERSION = 2025.10.13
BASE_FFMPEG_VERSION = 2025.10.13
BASE_FFMPEG_NVIDIA_VERSION = 2025.10.13
BASE_PYTHON_VERSION = 2025.10.13
BASE_CUDA_VERSION = 2025.10.13
BASE_OLLAMA_VERSION = 2025.09.22
BASE_PROSODY_VERSION = 2025.10.13

# OS images
ALPINE_IMAGE = ironbank/opensource/alpinelinux/alpine:3.22
# Base distroless includes glibc and libssl. ~21MB
DISTROLESS_IMAGE = ironbank/google/distroless/base:2025.10.13
# Apps that don't need libc, can use static. ~2MB
DISTROLESS_STATIC_IMAGE = ironbank/google/distroless/static:nonroot
DISTROLESS_JAVA_IMAGE = ironbank/google/distroless/java-21:nonroot
DEBIAN_SLIM_IMAGE = ironbank/opensource/debian/debian:12-slim
UBI9_TAG = 9.6

# Argus (AI) related variables
MODEL_TAG ?= 2025.08.29
JITSI_SKYNET_TAG ?= 2025.09.19
OLLAMA_VERSION = v0.11.11

GO_VERSION = 1.25.1
GO_DOCKER_IMAGE = ironbank/google/golang/ubi9/golang:$(GO_VERSION)

VITE_APP_VERSION ?= dev

PG_MAJOR_VERSION = 17
PG_MINOR_VERSION = 0

POETRY_VERSION = 2.1.3
PYTHON_311_PATCH = 13
PYTHON_312_PATCH = 11

# Services and apps
GEOSERVER_VERSION ?= 2025.3.5
# Get updated versions from 'ironbank/opensource/nginx/nginx' and push to ECR.
NGINX_VERSION=1.29.1
KEYCLOAK_VERSION=26.4.0

# opentdf version control
PLATFORM_VERSION=v0.8.0
OTDFCTL_VERSION=v0.24.0

# Docker build args and commands
BARG_ECR_REGISTRY = --build-arg AWS_ECR_REPO=$(AWS_ECR_REPO)
BARG_UID = --build-arg UID=$(UID)
BARG_GID = --build-arg GID=$(GID)
BARG_GO = --build-arg GO_DOCKER_IMAGE=$(GO_DOCKER_IMAGE)
BARG_GO_VERSION = --build-arg GO_VERSION=$(GO_VERSION)
BARG_ALPINE_IMAGE = --build-arg ALPINE_IMAGE=$(ALPINE_IMAGE)
BARG_UBI9_VERSION = --build-arg BASE_UBI9_VERSION=$(BASE_UBI9_VERSION)
BARG_RECORD_VERSIONS = --build-arg BASE_RECORD_BUILD_VERSION=$(BASE_RECORD_BUILD_VERSION) \
                       --build-arg BASE_RECORD_RUN_VERSION=$(BASE_RECORD_RUN_VERSION)
BARG_BASE_LIBZMQ_VERSION = --build-arg BASE_LIBZMQ_VERSION=$(BASE_LIBZMQ_VERSION)
BARG_DEBIAN_SLIM_IMAGE = --build-arg DEBIAN_SLIM_IMAGE=$(DEBIAN_SLIM_IMAGE)
BARG_DISTROLESS_IMAGE = --build-arg DISTROLESS_IMAGE=$(DISTROLESS_IMAGE)
BARG_DISTROLESS_JAVA_IMAGE = --build-arg DISTROLESS_JAVA_IMAGE=$(DISTROLESS_JAVA_IMAGE)
BARG_DISTROLESS_STATIC_IMAGE = --build-arg DISTROLESS_STATIC_IMAGE=$(DISTROLESS_STATIC_IMAGE)
BARG_FFMPEG_VERSION = --build-arg BASE_FFMPEG_VERSION=$(BASE_FFMPEG_VERSION)
BARG_FFMPEG_NVIDIA_VERSION = --build-arg BASE_FFMPEG_NVIDIA_VERSION=$(BASE_FFMPEG_NVIDIA_VERSION)
BARG_POETRY_VERSION = --build-arg POETRY_VERSION=$(POETRY_VERSION)
BARG_BASE_PYTHON_VERSION = --build-arg BASE_PYTHON_VERSION=$(BASE_PYTHON_VERSION)
BARG_BASE_CUDA_VERSION = --build-arg BASE_CUDA_VERSION=$(BASE_CUDA_VERSION)
BARG_BASE_OLLAMA_VERSION = --build-arg BASE_OLLAMA_VERSION=$(BASE_OLLAMA_VERSION)
BARG_BASE_PROSODY_VERSION = --build-arg BASE_PROSODY_VERSION=$(BASE_PROSODY_VERSION)
BARG_PG_MAJOR_VERSION = --build-arg PG_MAJOR_VERSION=$(PG_MAJOR_VERSION)
BARG_PG_MINOR_VERSION = --build-arg PG_MINOR_VERSION=$(PG_MINOR_VERSION)
BARG_HF_TOKEN = --build-arg HF_TOKEN=$(HF_TOKEN)
BARG_MODEL_TAG = --build-arg MODEL_TAG=$(MODEL_TAG)
BARG_JITSI_SKYNET_TAG = --build-arg JITSI_SKYNET_TAG=$(JITSI_SKYNET_TAG)
BARG_OLLAMA_VERSION = --build-arg OLLAMA_VERSION=$(OLLAMA_VERSION)
BARG_DEBIAN_REPO = --build-arg DEBIAN_REPO=$(DEBIAN_REPO)
BARG_DEBIAN_TAG = --build-arg DEBIAN_TAG=$(DEBIAN_VERSION)
BARG_IMAGE_TAG_SUFFIX = --build-arg IMAGE_TAG_SUFFIX=$(IMAGE_TAG_SUFFIX)
BARG_KEYCLOAK_VERSION = --build-arg KEYCLOAK_VERSION=$(KEYCLOAK_VERSION)
BARG_PLATFORM_VERSION = --build-arg PLATFORM_VERSION=$(PLATFORM_VERSION)
BARG_OTDFCTL_VERSION = --build-arg OTDFCTL_VERSION=$(OTDFCTL_VERSION)

# Utility function to pass arguments to docker build
build_arg = --build-arg $(1)=$($(1))

# Build command for services in the "services/" dir. Takes target (service) name as an arg so you can just do: $(MAKESERVICE)
MAKESERVICE = $(BUILD_CMD) \
							$(BARG_ECR_REGISTRY) \
							$(BARG_UID) \
							$(BARG_GID) \
							$(BARG_GO) \
							$(BARG_BASE_PYTHON_VERSION) \
							$(BARG_ALPINE_IMAGE) \
							$(BARG_UBI9_VERSION) \
							$(BARG_DISTROLESS_IMAGE) \
							$(BARG_DISTROLESS_JAVA_IMAGE) \
							$(BARG_DISTROLESS_STATIC_IMAGE) \
							$(BARG_MODEL_TAG) \
							$(BARG_BASE_CUDA_VERSION) \
							$(BARG_JITSI_SKYNET_TAG) \
							$(BARG_BASE_OLLAMA_VERSION) \
							$(BARG_BASE_LIBZMQ_VERSION) \
							$(BARG_IMAGE_TAG_SUFFIX) \
							$(BARG_BASE_PROSODY_VERSION) \
							$(BARG_KEYCLOAK_VERSION) \
							$(BARG_PLATFORM_VERSION) \
							$(BARG_OTDFCTL_VERSION) \
							-f services/$@/Dockerfile \
							-t $(IMAGE_TAG) \
							services

MAKESERVICEATROOT = $(BUILD_CMD) $(BARG_ECR_REGISTRY) $(BARG_GO) $(BARG_ALPINE_IMAGE) $(BARG_UBI9_VERSION) $(BARG_DISTROLESS_IMAGE) -f services/$@/Dockerfile -t $(IMAGE_TAG) .
# Build command for Darknet (VPN) components.
MAKEVPNSERVICE = $(BUILD_CMD) $(BARG_ECR_REGISTRY) $(BARG_GO) $(BARG_ALPINE_IMAGE) $(BARG_UBI9_VERSION) -f services/$@/Dockerfile -t $(VPN_IMAGE_TAG) services
# Build command for base images in "util/base-images/" dir.
MAKEBASEIMAGE = $(BUILD_CMD) $(BARG_ECR_REGISTRY) $(BARG_UBI9_VERSION) -f util/base-images/$@/Dockerfile -t $(IMAGE_TAG) util/base-images/$@

.ONESHELL:

# This function is used to conditionally remove dependencies when running in CI
# Currently in CI, having the dependencies will mean that they will be rebuilt without cache
ci_deps = $(if $(CI),,$1)

.PHONY: util imagery hashicorp_vault

all: spilo hashicorp_vault

proto_deps: PREFIX_PATH ?= ${HOME}/.local
proto_deps: TEMP_PATH ?= /tmp/erp
proto_deps:
	if ! command -v protoc &> /dev/null; then \
		if [ ! -d "${TEMP_PATH}/grpc" ]; then \
			git clone \
				--recurse-submodules \
				-b v1.62.0 \
				--depth 1 \
				--shallow-submodules https://github.com/grpc/grpc \
				${TEMP_PATH}/grpc; \
		fi; \
		cd ${TEMP_PATH}/grpc/ && \
			mkdir -p ${TEMP_PATH}/grpc/cmake/build/ && \
			pushd ${TEMP_PATH}/grpc/cmake/build/ && \
			cmake -DgRPC_INSTALL=ON \
			-DgRPC_BUILD_TESTS=OFF \
			-DCMAKE_INSTALL_PREFIX=${PREFIX_PATH} \
			../.. && \
			make -j 4 && \
			make install; \
	fi
	go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2

