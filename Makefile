MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash
.SHELLFLAGS := -u -o pipefail -c
.PHONY: all default pull build-compile build-runtime run runtimed runbash clean distclean

all: run
default: run
### :TODO: make variables for different targets, use them in target specs

pull:
	-docker pull python:3.7-slim-buster

build-compile: pull
	docker build \
		--target openfaas-compile-image \
		--tag openfaas-compile-image .

build-runtime: build-compile
	docker build \
		--target openfaas-runtime-image \
		--tag openfaas-runtime-image:latest .

### Last build resulted in:
### openfaas-runtime-image   latest              228MB
### openfaas-compile-image   latest              484MB

run: build-runtime
	docker run --init --rm --cap-drop ALL -it openfaas-runtime-image:latest
runtimed: build-runtime
	/usr/bin/time -v docker run --init --cap-drop ALL --rm -it openfaas-runtime-image:latest
runbash: build-runtime
	docker run --init --rm --cap-drop ALL --user 1234 -it openfaas-runtime-image:latest bash

release: flatten

flatten: build-runtime
	./docker_flatten testbuild testbuild-flattened
	./docker_flatten openfaas-runtime-image:latest openfaas-runtime-image:release 

clean:
	-docker rmi openfaas-compile-image:latest openfaas-runtime-image:latest
distclean: clean
	-docker rmi python:3.7-slim-buster
