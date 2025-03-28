# Hambone

Arma 3 game server with mods support, Docker, and AWS scaffolding.

## Intro

Hambone includes a Dockerized Arma 3 game server, bundled with a TeamSpeak
server using Docker Compose. The game server container, with a mounted data
volume, downloads Arma 3 server from Steam, then downloads mods from a YAML
manifest file. Some quirks about running Arma 3 server in Linux, such as
renaming all mod files to lowercase, are handled by Python and Bash scripts. It
is possible to include userdata for the server including mods from source,
server profile, server config, and server runscript. The Docker Compose stack
may be run locally or on AWS.

In addition to the Docker project, an AWS CloudFormation stack is included for
managing cloud infrastructure in a cost efficient manner. Using the various
Makefile commands, the stack can be spun up, monitored, data volume snapshots
saved and restored, and the stack may be torn down when not in use to save on
cost. The stack includes a VPC, EC2 server, EBS volume, ECR container registry,
and more. Makefile commands are provided for deploying userdata and the built
Docker container to the cloud. The EC2 server is configured with a Systemd
service to pull and run the Docker Compose stack.

## Features

- Dockerized Arma 3 game server.
- Support for game mods from Steam and/or local files.
- Support for custom game server config, profile, missions, launch flags.
- Python and Bash scripts for configuring the game server environment.
- TeamSpeak server included in Docker Compose stack.
- AWS CloudFormation stack declaring necessary cloud Infrastructure as Code.
- Makefile for automating Docker and AWS commands.

## Usage

Environment files are required for Docker, AWS Makefile commands, and the game
server itself. Refer to the provided example files to create environment files
suitable for your needs.

Build and run the server locally:
```bash
make docker-build
make docker-run
```

Deploy AWS CFN stack:
```bash
make cfn-create
```

There are many other Makefile targets for various admin tasks, and they should
be self explanatory.
