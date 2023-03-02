# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:8879a398dedf0aadaacfbd332b29ff2f84bc39ae6d4e9c0a1109db27ac5ba012 AS xx

# Stage - Build Drone SSH
FROM  golang:1.20-alpine@sha256:87d0a3309b34e2ca732efd69fb899d3c420d3382370fd6e7e6d2cb5c930f27f9 as builder

# Copy xx scripts
COPY --from=xx / /

WORKDIR /src

ARG TARGETPLATFORM
ENV GO111MODULE=on
ENV CGO_ENABLED=0

# renovate: datasource=github-releases depName=appleboy/drone-ssh
ARG DRONE_SSH_VERSION=v1.6.10

RUN apk --update --no-cache add git && \
    # Git clone specify drone-ssh version
    git clone --branch ${DRONE_SSH_VERSION} https://github.com/appleboy/drone-ssh . && \
    # Build drone-ssh
    xx-go build -v -o /bin/drone-ssh \
    -ldflags="-w -s -X 'main.Version=${DRONE_SSH_VERSION}'" . && \
    # Verify drone-ssh
    xx-verify --static /bin/drone-ssh

# Stage - Main Image
FROM plugins/base:latest@sha256:86ef1c54a3322ab1be06fbda6902d08350a29bde047944100a89c5c9ae182044

# Copy Drone SSH binary to image
COPY --from=builder /bin/drone-ssh /bin/drone-ssh

ENTRYPOINT ["/bin/drone-ssh"]
