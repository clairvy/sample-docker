DOCKER = docker -H $(DOCKER_HOST)
DOCKER_HOST = $(shell boot2docker up 2>&1 | awk -F= '/export/{print $$2}')
DOCKER_RUN_OPTS = --volumes-from my-data
DOCKER_RUN_ANOTHER_OPTS = $(shell if [ -f docker_run_another_opt.conf ]; then cat docker_run_another_opt.conf; fi)
DOCKER_RUN_INIT_CMD = $(shell if [ -f docker_run_init_cmd.conf ]; then cat docker_run_init_cmd.conf; fi)
BASE = erlang
SSH = LANG=C LC_ALL=C ssh
SSH_OPTS = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $(SSH_PORT)
SSH_PORT = $(shell $(DOCKER) port $(BASE) 22 | awk -F: '{print $$2}')
SSH_USER = kitchen
SSH_HOST = $(shell boot2docker ip 2>&1 | awk -F: '/IP/{print $$2}' | sed -e 's/ //')
AWK = awk
GREP = grep
IS_CONTAINER_EXIST = $(DOCKER) inspect $(BASE) | $(GREP) 'Pid' > /dev/null 2>&1
IS_CONTAINER_STOP = $(DOCKER) inspect $(BASE) | $(AWK) '/Pid/{print $$2}' | $(GREP) '^0,' > /dev/null 2>&1
GENERATED_FILES = keys/id_rsa

default: build

# ----------------------------------------
run: init start
	if ! $(IS_CONTAINER_EXIST); then \
  $(DOCKER) run $(DOCKER_RUN_OPTS) -d -P $(DOCKER_RUN_ANOTHER_OPTS) --name $(BASE) $(BASE); \
  fi

start:
	if $(IS_CONTAINER_STOP); then \
  $(DOCKER) start $(BASE); \
  fi

init:
	if [ -f docker_run_init_cmd.conf ]; then \
  if ! $(IS_CONTAINER_EXIST); then \
  $(DOCKER) run $(DOCKER_RUN_OPTS) -i -t --rm $(DOCKER_RUN_ANOTHER_OPTS) $(BASE) $(DOCKER_RUN_INIT_CMD); \
  fi; \
  fi

# ----------------------------------------
login: keys/id_rsa
	$(SSH) $(SSH_OPTS) -i keys/id_rsa $(SSH_USER)@$(SSH_HOST)

keys/id_rsa:
	$(DOCKER) cp $(BASE):/home/kitchen/.ssh/id_rsa $@

# ----------------------------------------
build:
	$(DOCKER) build -t $(BASE) .

destroy:
	if $(IS_CONTAINER_EXIST); then \
  $(DOCKER) stop $(BASE); $(DOCKER) rm $(BASE); \
  fi

clean:
	$(RM) $(RMF) $(GENERATED_FILES)
