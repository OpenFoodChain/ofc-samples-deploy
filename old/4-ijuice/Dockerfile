FROM ubuntu:18.04
RUN apt-get update && \
 apt-get install -y libevent-dev libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev build-essential pkg-config libc6-dev m4 g++-multilib autoconf libtool ncurses-dev python-zmq zlib1g-dev wget curl bsdmainutils automake cmake clang libsodium-dev libcurl4-gnutls-dev libssl-dev git unzip python jq htop
RUN cd ~ && \
  git clone https://github.com/mixa84/komodo.git 
RUN  cd ~/komodo && \
  git checkout cc_mixed 
RUN cd ~/komodo && \
  ./zcutil/build.sh -j4

RUN cd ~/komodo && \
  ./zcutil/fetch-params.sh 

RUN apt-get update && \
  apt-get install -y screen vim


# EXPOSE p2p port for the node to communicate on p2p network
EXPOSE 24707
# EXPOSE rpc port for the node to allow outside container access
EXPOSE 24708

ADD entrypoint.sh /usr/local/bin
ADD start-ijuice.sh /root

# CMD provides defaults for an executing container
#CMD ["/bin/bash"]
#CMD ["/root/start-ijuice.sh"]
CMD ["/usr/local/bin/entrypoint.sh"]

#docker run -i -t -p 127.0.0.1:24708:24708 -p 24707:24707 komodod_ijuice

#FROM ANOTHER TERMINAL
#curl --user someuser:somepass --data '{"method": "getinfo"}' http://127.0.0.1:7771
