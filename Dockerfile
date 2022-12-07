FROM ubuntu:20.04

RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1001 ubuntu && apt update && apt install -y curl docker.io && usermod -aG docker ubuntu
USER ubuntu
WORKDIR /home/ubuntu

RUN curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash
COPY .github /home/ubuntu/.github