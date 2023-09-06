### create a new github release

tarball = dist/$(project)-$(version).tgz
.release: $(wheel)
ifeq "$(version)" "$(subst v,,$(shell gh -R $(GITHUB_ORG)/$(project) release view --json name --jq .name))"
	@echo version $(version) is already released
else
	gh release create v$(version) --generate-notes --target master;
	tar zcf $(tarball) .
	gh release upload v$(version) $(tarball)
endif
	@touch $@

release: .release



release-clean:
	rm -f .release


release-sterile:
	@:
