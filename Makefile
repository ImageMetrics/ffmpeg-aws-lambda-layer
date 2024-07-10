STACK_NAME ?= ffmpeg

# by default get the latest. User FFMPEG_VERSION CLI param to override the version
ffmpeg_latest_url = https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-arm64-static.tar.xz
ffmpeg_current_url = $(ffmpeg_latest_url)

ffmpeg_version_in_layer = latest
ffmpeg_version_friendly = latest

ifneq ($(FFMPEG_VERSION),)
ffmpeg_current_url = https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-$(FFMPEG_VERSION)-arm64-static.tar.xz
STACK_NAME := $(STACK_NAME)-$(subst .,-,$(FFMPEG_VERSION))
ffmpeg_version_in_layer = $(subst .,-,$(FFMPEG_VERSION))
ffmpeg_version_friendly = $(FFMPEG_VERSION)
endif

STACK_NAME := $(STACK_NAME)-arm64-lambda-layer

$(info STACK_NAME is $(STACK_NAME))

clean: 
	rm -rf build

build/layer/bin/ffmpeg: 
	mkdir -p build/layer/bin
	rm -rf build/ffmpeg*
	cd build && curl $(ffmpeg_current_url) | tar x
	mv build/ffmpeg*/ffmpeg build/ffmpeg*/ffprobe build/layer/bin

build/output.yaml: template.yaml build/layer/bin/ffmpeg
	aws cloudformation package --template $< --s3-bucket $(DEPLOYMENT_BUCKET) --output-template-file $@

deploy: build/output.yaml
	aws cloudformation deploy --template $< --stack-name $(STACK_NAME) --parameter-overrides "ffmpegVersion=$(ffmpeg_version_in_layer)" "ffmpegFriendlyVersion=$(ffmpeg_version_friendly)"
	aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs --output table

deploy-example:
	cd example && \
		make deploy DEPLOYMENT_BUCKET=$(DEPLOYMENT_BUCKET) LAYER_STACK_NAME=$(STACK_NAME)
