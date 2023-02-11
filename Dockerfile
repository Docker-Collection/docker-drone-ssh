# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:66ffe58bd25bf822301324183a2a2743a4ed5db840253cc96b36694ef9e269d9 AS xx

# Stage - Build Drone SSH
FROM  golang:1.20-alpine@sha256:0d145ecb3cb3772ee54d3a97ae2774aa4f8a179f28f9d4ea67b9cb38b58acebd as builder

# Copy xx scripts
COPY --from=xx / /

WORKDIR /src

ARG TARGETPLATFORM
ENV GO111MODULE=on
ENV CGO_ENABLED=0

# renovate: datasource=github-releases depName=appleboy/drone-ssh
ARG DRONE_SSH_VERSION=v1.6.8

RUN apk --update --no-cache add git && \
    # Git clone specify drone-ssh version
    git clone --branch ${DRONE_SSH_VERSION} https://github.com/appleboy/drone-ssh . && \
    # Build drone-ssh
    xx-go build -v -o /bin/drone-ssh \
    -ldflags="-w -s -X 'main.Version=${DRONE_SSH_VERSION}'" . && \
    # Verify drone-ssh
    xx-verify --static /bin/drone-ssh

# Stage - Main Image
FROM plugins/base:latest@sha256:1455bbb0c08f6e9529fb7de5753b410bc23fbeea1f6c426f1209e2170e8d85c9

# Copy Drone SSH binary to image
COPY --from=builder /bin/drone-ssh /bin/drone-ssh

ENTRYPOINT ["/bin/drone-ssh"]
