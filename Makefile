SSH = LANG=C LC_ALL=C ssh
SSH_OPTS = -o 'StrictHostKeyChecking=no'
DOCKER_HOST = $(shell boot2docker up 2>&1 | awk -F= '/export/{print $$2}')
DOCKER = docker -H $(DOCKER_HOST)
DOCKER_RUN_OPTS = -p 80
NAME = nginx
SSH_USER = kitchen
SSH_PORT = 22
DOCKER_IP = $(shell boot2docker ip 2>&1 |awk -F: '/IP/{print $$2}'|sed -e 's/ //')
GIT = git
REPO = git@github.com:clairvy/sample-chef-repo.git
BRANCH = erlang
BERKS = bin/berks
BUNDLE = bundle
KNIFE_SOLO = LANG=C LC_ALL=C bin/knife solo
KNIFE_SOLO_OPTS = -i ../id_rsa -p `cat ../CONTAINER_SSH_PORT`
SED = sed

default: build

run: id_rsa

login: id_rsa
	$(SSH) $(SSH_OPTS) -i id_rsa -p `cat CONTAINER_SSH_PORT` $(SSH_USER)@$(DOCKER_IP)


id_rsa: CONTAINER_SSH_PORT
	$(DOCKER) cp `cat CONTAINER_ID`:/home/$(SSH_USER)/.ssh/id_rsa id_rsa

CONTAINER_SSH_PORT: CONTAINER_ID
	cat CONTAINER_ID|xargs -I {} $(DOCKER) port {} $(SSH_PORT) | awk -F: '{print $$2}' > $@

CONTAINER_ID:
	$(DOCKER) run $(DOCKER_RUN_OPTS) -d -p $(SSH_PORT) $(NAME) > $@

build:
	$(DOCKER) build -t $(NAME) .


echo: CONTAINER_SSH_PORT
	echo LANG=C LC_ALL=C knife solo prepare -i id_rsa -p `cat CONTAINER_SSH_PORT` $(SSH_USER)@$(DOCKER_IP)

knife: id_rsa chef-repo/nodes/$(DOCKER_IP).json
	cd chef-repo && $(KNIFE_SOLO) cook $(KNIFE_SOLO_OPTS) $(SSH_USER)@$(DOCKER_IP)

chef-repo/nodes/$(DOCKER_IP).json: chef-repo
	cd chef-repo && $(KNIFE_SOLO) prepare $(KNIFE_SOLO_OPTS) $(SSH_USER)@$(DOCKER_IP)
	$(SED) -i.bak -e 's/^$$/    "recipe[sample-erlang]"/' chef-repo/nodes/$(DOCKER_IP).json

chef-repo:
	$(GIT) clone $(REPO) $@ && cd $@ && if [ x"$(BRANCH)" != x"" ]; then $(GIT) checkout $(BRANCH); fi
	cd $@ && $(BUNDLE) install --binstubs=bin --path=vendor/bundle && $(BERKS) install


destroy:
	$(DOCKER) stop `cat CONTAINER_ID`
	$(DOCKER) rm `cat CONTAINER_ID`
	$(RM) CONTAINER_ID
	$(RM) CONTAINER_SSH_PORT

clean:
	$(RM) $(RMF) *~ .*~
