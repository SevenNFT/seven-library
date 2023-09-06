# common - initialization, variables, functions

# set make variables from project files
project = seven-library
version := $(shell cat VERSION)
src_dirs := ./contracts
src := $(foreach dir,$(src_dirs),$(wildcard $(dir)/*.sol))
git_commit := $(shell git log -1 | awk '/^commit/{print $$2}')

# sanity checks
$(if $(shell [ -d ../"$(project)" ] || echo X),$(error project dir $(project) not found))
$(if $(shell [ $$(readlink -e ../$(project)) = $$(readlink -e .) ] || echo X),$(error mismatch: $(project) != .))
$(if $(version),,$(error failed to read version from VERSION))

names:
	@echo project=$(project)
	@echo version=$(version)
	@echo src_dirs=$(src_dirs)
	@echo git_commit=$(git_commit)

	
### list make targets with descriptions
help:	
	@set -e;\
	echo;\
	echo 'Target        | Description';\
	echo '------------- | --------------------------------------------------------------';\
	for FILE in $(call makefiles); do\
	  awk <$$FILE  -F':' '\
	    BEGIN {help="begin"}\
	    /^##.*/ { help=$$0; }\
	    /^[a-z-]*:/ { if (last==help){ printf("%-14s| %s\n", $$1, substr(help,4));} }\
	    /.*/{ last=$$0 }\
	  ';\
	done;\
	echo

short-help:
	@echo "\nUsage: make TARGET\n";\
	echo $$($(MAKE) --no-print-directory help | tail +4 | awk -F'|' '{print $$1}'|sort)|fold -s -w 60;\
	echo

# add the cli help to the README
README.md: $(module)/cli.py
	awk <$@ >README.new -v flag=0 '/^## CLI/{flag=1} /```/{if(flag) exit} {print $$0}';\
	echo '```' >>README.new;\
	$(cli) --help >>README.new;\
	echo '```' >>README.new;\
	mv README.new $@;\

#
# --- functions ---
#

# break with an error if there are uncommited changes
define gitclean =
	$(if $(and $(if $(ALLOW_DIRTY),,1),$(shell git status --porcelain)),$(error git status: dirty, commit and push first))
endef

# require user confirmation   example: $(call verify_action,do something destructive)
define verify_action =
	$(if $(shell \
	read -p 'About to $(1). Confirm? [no] :' OK;\
	echo $$OK|grep '^[yY][eE]*[sS]*$$'\
	),$(info Confirmed),$(error Cowardly refusing))
endef

# github repo latest release version

# make clean targets
common-clean:
	@:

common-sterile:
	@:

### remove temporary files
clean:
	@$(MAKE) --no-print-directory $(addsuffix -clean,$(notdir $(basename $(wildcard make/*.mk))))

### remove all derived files
sterile: clean
	@$(MAKE) --no-print-directory $(addsuffix -sterile,$(notdir $(basename $(wildcard make/*.mk))))
