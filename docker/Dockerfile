FROM steamcmd/steamcmd:alpine

# Install Python
RUN apk update && apk add --no-cache python3

# Filesystem setup
ARG SERVER_UID=10001
ARG SERVER_GID=10001
RUN mkdir /home/server                            \
    && addgroup -g $SERVER_GID server             \
    && adduser -D -u $SERVER_UID -G server server \
    && mkdir -p /data                             \
    && chown -R server:server /data               \
    && chmod 0755 /data
VOLUME /data

# Working environment
USER server
ENV HOME=/home/server
WORKDIR /home/server
COPY scripts /home/server

# Venv
RUN python3 -m venv .venv                       \
    && . .venv/bin/activate                     \
    && pip install pyyaml

EXPOSE 2302/udp
EXPOSE 2303/udp
EXPOSE 2304/udp
EXPOSE 2305/udp
EXPOSE 2306/udp

ENTRYPOINT ["bash", "app.bash"]
