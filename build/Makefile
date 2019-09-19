MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash
.SHELLFLAGS := -u -o pipefail -c

MAINPROG := openfaas
all: $(MAINPROG)

$(MAINPROG).c: $(MAINPROG).py
	chmod 755 $(MAINPROG).py
	### generates a C file from Python source
	cython -3 --embed $^ -o $@

$(MAINPROG): $(MAINPROG).c
	$(eval INCLUDES := $(shell python3.7-config --includes))
	$(eval LIBS := $(shell python3.7-config --libs))
	$(eval CFLAGS := $(shell python3.7-config --cflags))
	gcc $(CFLAGS) \
		$(INCLUDES) \
		$(LIBS) \
		-o $@ $<
	chmod 755 $(MAINPROG)
