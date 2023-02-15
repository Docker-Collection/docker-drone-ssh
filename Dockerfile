# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:8879a398dedf0aadaacfbd332b29ff2f84bc39ae6d4e9c0a1109db27ac5ba012 AS xx

# Stage - Build Drone SSH
FROM  golang:1.20-alpine@sha256:48f336ef8366b9d6246293e3047259d0f614ee167db1869bdbc343d6e09aed8a as builder

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
FROM plugins/base:latest@sha256:376d390ebad1ae373b560eb8a03f046644b8c1e674a96738c224f0edcdfddb54

# Copy Drone SSH binary to image
COPY --from=builder /bin/drone-ssh /bin/drone-ssh

ENTRYPOINT ["/bin/drone-ssh"]
