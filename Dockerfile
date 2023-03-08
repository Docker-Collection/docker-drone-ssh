# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:8879a398dedf0aadaacfbd332b29ff2f84bc39ae6d4e9c0a1109db27ac5ba012 AS xx

# Stage - Build Drone SSH
FROM  golang:1.20-alpine@sha256:4e6bc0eafc261b6c8ba9bd9999b6698e8cefbe21e6d90fbc10c34599d75dc608 as builder

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
FROM plugins/base:latest@sha256:83a0c6ac50408cd262b5273e7009de9b9bcd0fa55a15b7e33d5978c9702acc96

# Copy Drone SSH binary to image
COPY --from=builder /bin/drone-ssh /bin/drone-ssh

ENTRYPOINT ["/bin/drone-ssh"]
