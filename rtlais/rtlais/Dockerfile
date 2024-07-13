FROM alpine

RUN mkdir /app

RUN apk add \
  rtl-sdr \
  librtlsdr \
  librtlsdr-dev \
  libusb \
  git \
  build-base

WORKDIR /tmp
RUN git clone https://github.com/dgiardini/rtl-ais.git && \
  cd rtl-ais && \
  make && \
  cp ./rtl_ais /app/ && \
  cd .. && \
  wget https://www.stripydog.com/download/kplex-1.4.tgz && \
  tar -xzf kplex-1.4.tgz && \
  cd kplex-1.4 && \
  make && \
  cp ./kplex /app/

COPY ./files/kplex.conf /etc/kplex.conf

CMD /app/rtl_ais -n

