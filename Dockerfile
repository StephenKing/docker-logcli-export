# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM public.ecr.aws/ubuntu/ubuntu:24.04_stable

RUN apt-get update \
  && apt-get install -y curl unzip \
  && rm -rf /var/lib/apt/lists/*

RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=aarch64; else ARCHITECTURE=x86_64; fi \
  && curl https://awscli.amazonaws.com/awscli-exe-linux-$ARCHITECTURE.zip -o awscliv2.zip \
  && unzip -q awscliv2.zip \
  && ./aws/install \
  && rm -rf aws awscliv2.zip \
  && aws --version

RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; else ARCHITECTURE=amd64; fi \
  && curl --location https://github.com/grafana/loki/releases/download/v3.3.0/logcli-linux-$ARCHITECTURE.zip -o logcli-linux-$ARCHITECTURE.zip \
  && unzip -q logcli-linux-$ARCHITECTURE.zip \
  && mv logcli-linux-$ARCHITECTURE /usr/local/bin/logcli \
  && logcli --version

COPY --chmod=0744 query.sh /query.sh

RUN /query.sh

CMD [ "/bin/sh"]