FROM ubuntu:jammy

RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1001 ubuntu && apt update && apt install -y curl git
#USER ubuntu
WORKDIR /home/ubuntu

RUN curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash
RUN curl https://github.com/unity-sds/unity-control-plane/releases/download/0.1.4-Alpha/unity-control-plane-0.1.4-Alpha-linux-amd64.tar.gz -o /home/ubuntu/web
RUN echo "-P ubuntu-latest=catthehacker/ubuntu:act-latest \
-P ubuntu-22.04=catthehacker/ubuntu:act-22.04 \
-P ubuntu-20.04=catthehacker/ubuntu:act-20.04 \
-P ubuntu-18.04=catthehacker/ubuntu:act-18.04" > /root/.actrc

COPY . /home/ubuntu/unity-cs
