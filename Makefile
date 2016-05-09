.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

user = $(shell whoami)
ifeq ($(user),root)
$(error  "do not run as root! run 'gpasswd -a USER docker' on the user of your choice")
endif

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container
	@echo ""   2. make build     - build docker container
	@echo ""   3. make clean     - kill and remove docker container
	@echo ""   4. make enter     - execute an interactive bash in docker container
	@echo ""   3. make logs      - follow the logs of docker container

build: HOSTNAME NAME TAG OVPN_DATA OVPN_DATA_PATH OVPN_DATA_CID OVPN_INIT_CID builddocker

# run a plain container
run: build OVPN_CID

OVPN_INIT_CID:
	$(eval HOSTNAME := $(shell cat HOSTNAME))
	$(eval OVPN_DATA := $(shell cat OVPN_DATA))
	@docker run --volumes-from $(OVPN_DATA) --rm  --cidfile="OVPN_INIT_CID" -t kylemanna/openvpn ovpn_genconfig -u udp://$(HOSTNAME)
	@docker run  --volumes-from $(OVPN_DATA)  --rm  -it -t kylemanna/openvpn ovpninitpki

cert:
	$(eval NAME := $(shell cat NAME))
	$(eval OVPN_DATA := $(shell cat OVPN_DATA))
	@docker run \
	--volumes-from $(OVPN_DATA) \
	-d \
	-p  1194:1194/udp \
	--cap-add=NET_ADMIN \
	-t kylemanna/openvpn easyrsa build-client-full $(NAME) nopass
	@docker run \
	--volumes-from $(OVPN_DATA) \
	--rm \
	kylemanna/openvpn ovpn_getclient $(NAME) > $(NAME).ovpn

OVPN_CID:
	$(eval OVPN_DATA := $(shell cat OVPN_DATA))
	@docker run \
	--volumes-from $(OVPN_DATA) \
	-d \
	--cidfile="OVPN_CID" \
	-p  1194:1194/udp \
	--cap-add=NET_ADMIN \
	-t kylemanna/openvpn

OVPN_DATA_CID:
	$(eval OVPN_DATA := $(shell cat OVPN_DATA))
	$(eval OVPN_DATA_PATH := $(shell cat OVPN_DATA_PATH))
	@docker run --name=$(OVPN_DATA) --cidfile="OVPN_DATA_CID" -v $(OVPN_DATA_PATH):/etc/openvpn busybox

OVPN_DATA_PATH:
	@while [ -z "$$OVPN_DATA_PATH" ]; do \
		read -r -p "Enter the MySQL password you wish to associate with this container [OVPN_DATA_PATH]: " OVPN_DATA_PATH; echo "$$OVPN_DATA_PATH">>OVPN_DATA_PATH; cat OVPN_DATA_PATH; \
	done ;

OVPN_DATA:
	@while [ -z "$$OVPN_DATA" ]; do \
		read -r -p "Enter thename of a data container you wish to associate with this container [OVPN_DATA]: " OVPN_DATA; echo "$$OVPN_DATA">>OVPN_DATA; cat OVPN_DATA; \
	done ;

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this container [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

HOSTNAME:
	@while [ -z "$$HOSTNAME" ]; do \
		read -r -p "Enter thehost name you wish to associate with this container [HOSTNAME]: " HOSTNAME; echo "$$HOSTNAME">>HOSTNAME; cat HOSTNAME; \
	done ;
