ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG=C.UTF-8

RUN apk add --no-cache \
        borgbackup \
        openssh-keygen \
        openssh-client

# Home Assistant CLI
ARG BUILD_ARCH
RUN curl -Lso /usr/bin/ha "https://github.com/home-assistant/cli/releases/latest/download/ha_${BUILD_ARCH}"
RUN chmod +x /usr/bin/ha

# Copy required data for add-on
COPY run.sh /
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
