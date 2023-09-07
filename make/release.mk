### create a new github release

github = gh -R $(organization)/$(project)

tarball = dist/$(project)-$(version).tgz

$(tarball): 
	tar zcf $@ .

.tarball: $(tarball)
	@touch $@

tarball: .tarball

.release: .tarball
ifeq "$(version)" "$(subst v,,$(shell $(github) release view --json name --jq .name))"
	@echo version $(version) is already released
else
	$(github) release create v$(version) --generate-notes --target master;
	$(github) release upload v$(version) $(tarball)
endif
	@touch $@

release: .release 

release-clean:
	rm -f .release
	rm -f dist/*.tgz

release-sterile:
	@:
