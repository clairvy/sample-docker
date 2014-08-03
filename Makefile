SSH = LANG=C LC_ALL=C ssh
SSH_OPTS = -o 'StrictHostKeyChecking=no'
DOCKER_HOST = $(shell boot2docker up 2>&1 | awk -F= '/export/{print $$2}')
DOCKER = docker -H $(DOCKER_HOST)
NAME = sample-base
SSH_USER = kitchen
SSH_PORT = 22
DOCKER_IP = $(shell boot2docker ip 2>&1 |awk -F: '/IP/{print $$2}'|sed -e 's/ //')

default: build

run: id_rsa

id_rsa: CONTAINER_SSH_PORT
	$(DOCKER) cp `cat CONTAINER_ID`:/home/$(SSH_USER)/.ssh/id_rsa id_rsa

CONTAINER_SSH_PORT: CONTAINER_ID
	cat CONTAINER_ID|xargs -I {} $(DOCKER) port {} $(SSH_PORT) | awk -F: '{print $$2}' > $@

CONTAINER_ID:
	$(DOCKER) run -d -p $(SSH_PORT) $(NAME) > $@

build:
	$(DOCKER) build -t $(NAME) .

login: id_rsa
	$(SSH) $(SSH_OPTS) -i id_rsa -p `cat CONTAINER_SSH_PORT` $(SSH_USER)@$(DOCKER_IP)

destroy:
	$(DOCKER) stop `cat CONTAINER_ID`
	$(DOCKER) rm `cat CONTAINER_ID`
	$(RM) CONTAINER_ID
	$(RM) CONTAINER_SSH_PORT

echo: CONTAINER_SSH_PORT
	echo LANG=C LC_ALL=C knife solo prepare -i id_rsa -p `cat CONTAINER_SSH_PORT` $(SSH_USER)@$(DOCKER_IP)

clean:
	$(RM) $(RMF) *~ .*~
