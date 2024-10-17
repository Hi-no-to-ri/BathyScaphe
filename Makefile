# 
# makefile for BathyScaphe all products.
#

WORKSPACE = BathyScaphe.xcworkspace
OPTIONS = -configuration Release -workspace $(WORKSPACE)
MDI_DIR = ./metadataimporter/BathyScaphe


all: bathyscaphe

clean: clean-bathyscaphe

bathyscaphe:
	xcodebuild -scheme All $(OPTIONS)

components: frameworks mdimporter quicklookgenerator

# Frameworks
.PHONY: frameworks

frameworks: SGFoundation SGAppKit CocoMonar CocoaOniguruma

SGFoundation:
	xcodebuild -scheme $@ $(OPTIONS)

SGAppKit:
	xcodebuild -scheme $@ $(OPTIONS)

CocoMonar:
	xcodebuild -scheme "CocoMonar Framework" $(OPTIONS)

CocoaOniguruma:
	xcodebuild -scheme $@ $(OPTIONS)

# Other components
mdimporter:
	xcodebuild -project $(MDI_DIR)/BathyScapheMDI.xcodeproj -configuration Release

quicklookgenerator:
	xcodebuild -scheme "Build for BathyScaphe" $(OPTIONS)


# clean

clean-bathyscaphe:
	xcodebuild -scheme All $(OPTIONS) clean

clean-components: clean-frameworks clean-mdimporter clean-quicklookgenerator

clean-frameworks: clean-SGFoundation clean-SGAppKit clean-CocoMonar clean-CocoaOniguruma

clean-SGFoundation:
	xcodebuild -scheme SGFoundation $(OPTIONS) clean

clean-SGAppKit:
	xcodebuild -scheme SGAppKit $(OPTIONS) clean

clean-CocoMonar:
	xcodebuild -scheme "CocoMonar Framework" $(OPTIONS) clean

clean-CocoaOniguruma:
	xcodebuild -scheme CocoaOniguruma $(OPTIONS) clean

clean-mdimporter:
	xcodebuild -project $(MDI_DIR)/BathyScapheMDI.xcodeproj clean
	rm -fr $(MDI_DIR)/build

clean-quicklookgenerator:
	xcodebuild -scheme "Build for BathyScaphe" $(OPTIONS) clean

