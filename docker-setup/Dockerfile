FROM ubuntu:22.04
# FROM python:3.9.17-buster

RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update -y \
  && apt-get install -y \
  python3-pip \
  sudo \
  passwd \
  curl \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

# ---- FROM https://stackoverflow.com/a/49848507 ----
RUN addgroup --gid 1000 vagrant \
  && useradd -rm -d /home/vagrant -s /bin/bash -g 1000 -G 1000 -u 1000 vagrant \
  && echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

COPY systemctl3.py /usr/bin/systemctl
CMD ["/usr/bin/systemctl"]

# Switch to the "vagrant" user
USER vagrant
# Set the working directory to the user's home directory
WORKDIR /home/vagrant
