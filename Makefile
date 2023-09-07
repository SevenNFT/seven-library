# top-level Makefile 

.PHONY: usage update

usage: short-help

openzeppelin-contracts:
	git clone git@github.com:OpenZeppelin/$@

update: openzeppelin-contracts
	cd $<; git pull
	rm -rf contracts/openzeppelin
	./update ./openzeppelin-contracts/contracts 


include $(wildcard make/*.mk)
