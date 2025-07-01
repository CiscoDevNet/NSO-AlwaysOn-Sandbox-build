all: fxs
.PHONY: all

# Include standard NCS examples build definitions and rules
include $(NCS_DIR)/src/ncs/build/include.ncs.mk

SRC  = $(wildcard yang/*.yang)
DIRS = ../load-dir
FXS = $(SRC:yang/%.yang=../load-dir/%.fxs)

##
## YANGPATH edited to add NED required for the example
##
YANGPATH += ${NCS_RUN_DIR}/packages/cisco-ios-cli-3.8/src/ncsc-out/modules/yang
YANGPATH += ${NCS_RUN_DIR}/packages/cisco-asa-cli-6.6/src/ncsc-out/modules/yang
YANGPATH += ${NCS_RUN_DIR}/packages/cisco-iosxr-cli-3.5/src/ncsc-out/modules/yang
YANGPATH += ${NCS_RUN_DIR}/packages/cisco-nx-cli-3.0/src/ncsc-out/modules/yang
YANGPATH += ./yang


NCSCPATH   = $(YANGPATH:%=--yangpath %)
YANGERPATH = $(YANGPATH:%=--path %)

fxs: $(DIRS) $(FXS)
.PHONY: fxs

$(DIRS):
	mkdir -p $@

## Edited yang/router.yang to compile only router.yang
../load-dir/%.fxs: yang/router.yang
	$(NCSC) `ls $*-ann.yang  > /dev/null 2>&1 && echo "-a $*-ann.yang"` \
		--fail-on-warnings \
		$(NCSCPATH) \
		-c -o $@ $<
clean:
	rm -rf $(DIRS)
.PHONY: clean