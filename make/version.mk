# version - automatic version management
 
# - Prevent version changes with uncommited changes
# - tag and commit version changes
# - Use 'lightweight tags'

define BUMPVERSION_CFG
[bumpversion]
current_version = $(version)
commit = True
tag = True
[bumpversion:file:VERSION]
search = {current_version}
replace = {new_version}
endef

export BUMPVERSION_CFG

bumpversion = bumpversion --allow-dirty $(1) && git push

bump: bump-patch

### bump patch version
bump-patch: version-update
	$(call bumpversion,patch)

### bump minor version, reset patch to zero
bump-minor: version-update
	$(call bumpversion,minor)
	
### bump major version, reset minor and patch to zero
bump-major: version-update
	$(call bumpversion,major)

# assert gitclean, rewrite requirements.txt, update timestamp, apply version update
version-update:
	$(call gitclean)
	[ -f .bumpversion.cfg ] || { echo "$$BUMPVERSION_CFG" >.bumpversion.cfg; git add .bumpversion.cfg; }
	git add VERSION
	@echo "Updated VERSION"

# clean up version tempfiles
version-clean:
	@:

version-sterile:
	rm -f .bumpversion.cfg
