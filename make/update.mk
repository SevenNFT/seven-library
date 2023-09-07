# update openzeppelin library sources

.PHONY: update

OPENZEPPELIN_VERSION := 4.9.3

openzeppelin-contracts:
	git clone git@github.com:OpenZeppelin/$@

update: openzeppelin-contracts
	cd $<; git checkout master; git pull; git checkout v$(OPENZEPPELIN_VERSION) 
	rm -rf contracts/openzeppelin
	./update ./openzeppelin-contracts/contracts 

update-clean:
	rm -rf openzeppelin-contracts
