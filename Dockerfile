# Dockerfile
FROM ubuntu

RUN apt -y update && apt -y upgrade
RUN apt-get install -y curl
RUN curl -sSL https://get.haskellstack.org/ | sh

COPY . /usr/server

RUN cd usr/server && stack build

WORKDIR /usr/server
CMD ["stack", "exec", "server-exe"]
