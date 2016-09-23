#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2014, Joyent, Inc.
#

#
# Makefile: basic Makefile for template API service
#
# This Makefile is a template for new repos. It contains only repo-specific
# logic and uses included makefiles to supply common targets (javascriptlint,
# jsstyle, restdown, etc.), which are used by other repos as well. You may well
# need to rewrite most of this file, but you shouldn't need to touch the
# included makefiles.
#
# If you find yourself adding support for new targets that could be useful for
# other projects too, you should add these to the original versions of the
# included Makefiles (in eng.git) so that other teams can use them too.
#

#
# Tools
#
NPM       := npm
NODEUNIT	:= ./node_modules/.bin/nodeunit
NODEUNIT_ARGS   ?=

#
# Files
#
DOC_FILES	 = index.md
JS_FILES	:= $(shell find lib test -name '*.js')
JSL_CONF_NODE	 = tools/jsl.node.conf
JSL_FILES_NODE   = $(JS_FILES)
JSSTYLE_FILES	 = $(JS_FILES)
JSSTYLE_FLAGS    = -o indent=4,doxygen,unparenthesized-return=0

include ./tools/mk/Makefile.defs

#
# Repo-specific targets
#
.PHONY: all
all:
	$(NPM) install && $(NPM) rebuild

.PHONY: test ca_test ufds_test vmapi_test cnapi_test amon_test napi_test imgapi_test papi_test

ca_test: $(NODEUNIT)
	$(NODEUNIT) $(NODEUNIT_ARGS) test/ca.test.js

vmapi_test: $(NODEUNIT)
	$(NODEUNIT) $(NODEUNIT_ARGS) test/vmapi.test.js

cnapi_test: $(NODEUNIT)
	$(NODEUNIT) $(NODEUNIT_ARGS) test/cnapi.test.js

ufds_test: $(NODEUNIT)
	$(NODEUNIT) $(NODEUNIT_ARGS) test/ufds.test.js

amon_test: $(NODEUNIT)
	$(NODEUNIT) $(NODEUNIT_ARGS) test/amon.test.js

napi_test: $(NODEUNIT)
	$(NODEUNIT) $(NODEUNIT_ARGS) test/napi.test.js

dsapi_test: $(NODEUNIT)
	$(NODEUNIT) $(NODEUNIT_ARGS) test/dsapi.test.js

papi_test: $(NODEUNIT)
	$(NODEUNIT) $(NODEUNIT_ARGS) test/papi.test.js

cns_test: $(NODEUNIT)
	$(NODEUNIT) $(NODEUNIT_ARGS) test/cns.test.js

test: ca_test ufds_test cnapi_test napi_test vmapi_test papi_test cns_test

.PHONY: setup
setup:
	$(NPM) install

# Ensure CHANGES.md and package.json have the same version.
.PHONY: versioncheck
versioncheck:
	@echo version is: $(shell cat package.json | json version)
	[[ `cat package.json | json version` == `grep '^## ' CHANGES.md | head -1 | awk '{print $$2}'` ]]

.PHONY: cutarelease
cutarelease: versioncheck
	[[ -z `git status --short` ]]  # If this fails, the working dir is dirty.
	@which json 2>/dev/null 1>/dev/null && \
	    ver=$(shell json -f package.json version) && \
	    name=$(shell json -f package.json name) && \
	    publishedVer=$(shell npm view -j $(shell json -f package.json name)@$(shell json -f package.json version) version 2>/dev/null) && \
	    if [[ -n "$$publishedVer" ]]; then \
		echo "error: $$name@$$ver is already published to npm"; \
		exit 1; \
	    fi && \
	    echo "** Are you sure you want to tag and publish $$name@$$ver to npm?" && \
	    echo "** Enter to continue, Ctrl+C to abort." && \
	    read
	ver=$(shell cat package.json | json version) && \
	    date=$(shell date -u "+%Y-%m-%d") && \
	    git tag -a "v$$ver" -m "version $$ver ($$date)" && \
	    git push --tags origin && \
	    npm publish

include ./tools/mk/Makefile.deps
include ./tools/mk/Makefile.targ
