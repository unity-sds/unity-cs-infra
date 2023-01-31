FROM ubuntu:jammy

RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1001 ubuntu && apt update && apt install -y curl git jq unzip && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
#USER ubuntu
WORKDIR /home/ubuntu

RUN curl https://raw.githubusercontent.com/nektos/act/master/install.sh | bash
RUN curl -L -s https://github.com/unity-sds/unity-control-plane/releases/download/0.1.9-Alpha/unity-control-plane-0.1.9-Alpha-linux-amd64.tar.gz | tar -xz
RUN chmod +x /home/ubuntu/unity-control-plane
RUN echo "-P ubuntu-latest=catthehacker/ubuntu:act-latest\n \
-P ubuntu-22.04=catthehacker/ubuntu:act-22.04\n \
-P ubuntu-20.04=catthehacker/ubuntu:act-20.04\n \
-P ubuntu-18.04=catthehacker/ubuntu:act-18.04" > /root/.actrc

COPY . /home/ubuntu/unity-cs

ENV PATH="${PATH}:/home/ubuntu/bin/"
ENV WORKFLOWPATH="/home/ubuntu/unity-cs/.github/workflows/"
ENTRYPOINT ["/home/ubuntu/unity-control-plane"]
