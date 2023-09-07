# top-level Makefile 

.PHONY: usage

usage: short-help

include $(wildcard make/*.mk)
