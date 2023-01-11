FROM ubuntu:jammy

RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1001 ubuntu && apt update && apt install -y curl git
#USER ubuntu
WORKDIR /home/ubuntu

RUN curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash
RUN curl -L -s https://github.com/unity-sds/unity-control-plane/releases/download/0.1.5-Alpha/unity-control-plane-0.1.5-Alpha-linux-amd64.tar.gz | tar -xz
RUN chmod +x /home/ubuntu/unity-control-plane
RUN echo "-P ubuntu-latest=catthehacker/ubuntu:act-latest\n \
-P ubuntu-22.04=catthehacker/ubuntu:act-22.04\n \
-P ubuntu-20.04=catthehacker/ubuntu:act-20.04\n \
-P ubuntu-18.04=catthehacker/ubuntu:act-18.04" > /root/.actrc

COPY . /home/ubuntu/unity-cs
ENTRYPOINT ["/home/ubuntu/unity-control-plane"]
