BASE_PATH=$(shell pwd)

.PHONY: build-codepilot-image
build-codepilot-image:
	@cd aws/ecs/copilot && docker image build -t codepilot .

.PHONY: build-tesseract-reader-image
build-tesseract-reader-image:
	@cd aws/ecs/tesseract-reader && docker image build -t tesseract-reader .

.PHONY: codepilot
codepilot:
	@docker container run -it --rm \
		-v $(BASE_PATH)/aws/config:/root/.aws \
		-v $(BASE_PATH)/$(APP):/app \
		-e AWS_SDK_LOAD_CONFIG=1 \
		-e AWS_PROFILE=default \
		codepilot:latest $(ARG)
