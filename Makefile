SHELL=/bin/bash

.PHONY: build run dev-deploy

build:
	docker run \
		--rm \
		-it \
		--name builder \
	    --privileged \
	    -v .:/data \
	    -v /var/run/docker.sock:/var/run/docker.sock:ro \
	    ghcr.io/home-assistant/amd64-builder \
	    -t /data \
	    --all \
	    --test \
	    -i home-assistant-borg-backup-dev \
	    -d local

run: build
	docker run --rm -v ./data:/data local/home-assistant-borg-backup-dev

dev-deploy:
	scp -r ../home-assistant-borg-backup steve:/addons
