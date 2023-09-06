### create a new github release

github = gh -R $(organization)/$(project)

tarball = dist/$(project)-$(version).tgz
.release: $(wheel)
ifeq "$(version)" "$(subst v,,$(shell $(github) release view --json name --jq .name))"
	@echo version $(version) is already released
else
	$(github) release create v$(version) --generate-notes --target master;
	tar zcf $(tarball) .
	$(github) release upload v$(version) $(tarball)
endif
	@touch $@

release: .release



release-clean:
	rm -f .release


release-sterile:
	@:
