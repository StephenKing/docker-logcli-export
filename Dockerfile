# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM public.ecr.aws/ubuntu/ubuntu:24.04_stable

RUN apt-get update \
  && apt-get install -y curl unzip \
  && rm -rf /var/lib/apt/lists/*

RUN curl https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip -o awscliv2.zip \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf aws awscliv2.zip

RUN curl --location https://github.com/grafana/loki/releases/download/v3.3.0/logcli-linux-arm64.zip -o logcli-linux-arm64.zip \
  && unzip -q logcli-linux-arm64.zip \
  && mv logcli-linux-arm64 /usr/local/bin/logcli

COPY --chmod=0744 query.sh /query.sh

CMD [ "/bin/sh"]