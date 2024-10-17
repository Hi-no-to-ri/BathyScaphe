
PRODUCT_NAME=BSLinkPreviewerSelector
PRODUCT_EXTENSION=plugin
BUILD_PATH=./build
DEPLOYMENT=Release
APP_BUNDLE=$(PRODUCT_NAME).$(PRODUCT_EXTENSION)
APP=$(BUILD_PATH)/$(DEPLOYMENT)/$(APP_BUNDLE)
APP_NAME=$(BUILD_PATH)/$(DEPLOYMENT)/$(PRODUCT_NAME)
INFO_PLIST=BSLinkPreviewSelector-Info.plist


all:
	@echo do  nothig.

updateVersion:
#	cd English.lproj && ${MAKE} $@
	cd ja.lproj && ${MAKE} $@

restoreInfoPlist:
#	cd English.lproj && ${MAKE} $@
	cd ja.lproj && ${MAKE} $@

Localizable:
#	genstrings -o English.lproj $^
#	cd English.lproj && ${MAKE} $@
	genstrings -o ja.lproj $^
	cd ja.lproj && ${MAKE} $@

checkLocalizable:
#	cd English.lproj && ${MAKE} $@
	cd ja.lproj && ${MAKE} $@
