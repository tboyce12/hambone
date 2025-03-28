FROM steamcmd/steamcmd:alpine

# Install Python
RUN apk update && apk add --no-cache python3

# Create data dir
RUN mkdir /home/server                          \
    && adduser -D -h /home/server server        \
    && mkdir -p /data                           \
    && chown -R server:server /data             \
    && chmod 0755 /data

USER server
ENV HOME=/home/server
WORKDIR /home/server
VOLUME /data
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
