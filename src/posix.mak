################################################################################
# Important variables:
# --------------------
#
# HOST_CXX:             C++ compiler to use (g++,clang++) for C++ frontend unittest
# HOST_DMD:             Host D compiler to use for bootstrapping
# AUTO_BOOTSTRAP:       Enable auto-boostrapping by downloading a stable DMD binary
# INSTALL_DIR:          Installation folder to use
# MODEL:                Target architecture to build for (32,64) - defaults to the host architecture
#
################################################################################
# Build modes:
# ------------
# BUILD: release (default) | debug (enabled a build with debug instructions)
#
# Opt-in build features:
#
# ENABLE_RELEASE:       Optimized release built
# ENABLE_DEBUG:         Add debug instructions and symbols (set if ENABLE_RELEASE isn't set)
# ENABLE_LTO:           Enable link-time optimizations
# ENABLE_UNITTEST:      Build dmd with unittests (sets ENABLE_COVERAGE=1)
# ENABLE_PROFILE:       Build dmd with a profiling recorder (D)
# ENABLE_COVERAGE       Build dmd with coverage counting
# ENABLE_SANITIZERS     Build dmd with sanitizer (e.g. ENABLE_SANITIZERS=address,undefined)
#
# Targets
# -------
#
# all					Build dmd
# unittest              Run all unittest blocks
# cxx-unittest          Check conformance of the C++ headers
# build-examples        Build DMD as library examples
# clean                 Remove all generated files
# man                   Generate the man pages
# checkwhitespace       Checks for trailing whitespace and tabs
# zip                   Packs all sources into a ZIP archive
# gitzip                Packs all sources into a ZIP archive
# install               Installs dmd into $(INSTALL_DIR)
################################################################################

# get OS and MODEL
include osmodel.mak

GENERATED = ../generated
G = $(GENERATED)/$(OS)/$(BUILD)/$(MODEL)
$(shell mkdir -p $G)

# Host D compiler for bootstrapping
ifeq (,$(AUTO_BOOTSTRAP))
  # No bootstrap, a $(HOST_DMD) installation must be available
  HOST_DMD?=dmd
  HOST_DMD_PATH=$(abspath $(shell which $(HOST_DMD)))
  ifeq (,$(HOST_DMD_PATH))
    #$(error '$(HOST_DMD)' not found, get a D compiler or make AUTO_BOOTSTRAP=1)
  endif
  HOST_DMD_RUN:=$(HOST_DMD)
else
  # Auto-bootstrapping, will download dmd automatically
  # Keep var below in sync with other occurrences of that variable, e.g. in circleci.sh
  HOST_DMD_VER=2.088.0
  HOST_DMD_ROOT=$(GENERATED)/host_dmd-$(HOST_DMD_VER)
  # dmd.2.088.0.osx.zip or dmd.2.088.0.linux.tar.xz
  HOST_DMD_BASENAME=dmd.$(HOST_DMD_VER).$(OS)$(if $(filter $(OS),freebsd),-$(MODEL),)
  # http://downloads.dlang.org/releases/2.x/2.088.0/dmd.2.088.0.linux.tar.xz
  HOST_DMD_URL=http://downloads.dlang.org/releases/2.x/$(HOST_DMD_VER)/$(HOST_DMD_BASENAME)
  HOST_DMD=$(HOST_DMD_ROOT)/dmd2/$(OS)/$(if $(filter $(OS),osx),bin,bin$(MODEL))/dmd
  HOST_DMD_PATH=$(HOST_DMD)
  HOST_DMD_RUN=$(HOST_DMD) -conf=$(dir $(HOST_DMD))dmd.conf
endif

RUN_BUILD = $(GENERATED)/build \
	    AUTO_BOOTSTRAP="$(AUTO_BOOTSTRAP)" \
	    MAKE="$(MAKE)" \
	    --called-from-make \

######## Begin build targets

all: dmd
.PHONY: all

dmd: $(GENERATED)/build
	$(RUN_BUILD) toolchain-info
.PHONY: dmd

$(GENERATED)/build: build.d $(HOST_DMD_PATH)
	$(HOST_DMD_RUN) -of$@ -g build.d

auto-tester-build: $(GENERATED)/build
	$(RUN_BUILD) $@

.PHONY: auto-tester-build

toolchain-info: $(GENERATED)/build
	$(RUN_BUILD) $@

unittest: $G/dmd-unittest
	$<

######## Manual cleanup

clean:
	rm -Rf $(GENERATED)

######## Download and install the last dmd buildable without dmd

ifneq (,$(AUTO_BOOTSTRAP))
CURL_FLAGS:=-fsSL --retry 5 --retry-max-time 120 --connect-timeout 5 --speed-time 30 --speed-limit 1024
$(HOST_DMD_PATH):
	mkdir -p ${HOST_DMD_ROOT}
ifneq (,$(shell which xz 2>/dev/null))
	curl ${CURL_FLAGS} ${HOST_DMD_URL}.tar.xz | tar -C ${HOST_DMD_ROOT} -Jxf - || rm -rf ${HOST_DMD_ROOT}
else
	TMPFILE=$$(mktemp deleteme.XXXXXXXX) &&	curl ${CURL_FLAGS} ${HOST_DMD_URL}.zip > $${TMPFILE}.zip && \
		unzip -qd ${HOST_DMD_ROOT} $${TMPFILE}.zip && rm $${TMPFILE}.zip;
endif
endif

FORCE: ;

################################################################################
# Generate the man pages
################################################################################


$(GENERATED)/docs/%: $(GENERATED)/build
	$(RUN_BUILD) $@

man: $(GENERATED)/build
	$(RUN_BUILD) $@

######################################################

install: $(GENERATED)/build
	$(RUN_BUILD) $@

######################################################

checkwhitespace: $(GENERATED)/build
	$(RUN_BUILD) $@

######################################################
# DScanner
######################################################

# runs static code analysis with Dscanner
style: $(GENERATED)/build
	$(RUN_BUILD) $@

######################################################

cxx-unittest: $(GENERATED)/build
	$(RUN_BUILD) $@

######################################################

zip: $(GENERATED)/build
	$(RUN_BUILD) $@

######################################################

gitzip:
	git archive --format=zip HEAD > $(ZIPFILE)

######################################################
# Default rule to forward targets to build.d

$G/%: $(GENERATED)/build FORCE
	$(RUN_BUILD) $@

################################################################################
# DDoc documentation generation
################################################################################


html: $(GENERATED)/build FORCE
	$(RUN_BUILD) $@

######################################################

.DELETE_ON_ERROR: # GNU Make directive (delete output files on error)
