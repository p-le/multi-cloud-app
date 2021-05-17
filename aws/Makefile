.PHONY: build-codepilot-image
build-codepilot-image:
	@cd aws/ecs/copilot && docker image build -t codepilot .

.PHONY: build-tesseract-reader-image
build-tesseract-reader-image:
	@cd aws/ecs/tesseract-reader && docker image build -t tesseract-reader .

.PHONY: build-s3-demo1-image
build-s3-demo1-image:
	@cd aws/s3/demo-1 && docker image build -t s3-demo1 .
	@docker image ls | grep s3-demo1

.PHONY: test-s3-demo1-image
test-s3-demo1-image:
	@docker image tag
	@docker container run \
		--rm -it \
		-v $(BASE_PATH)/aws/config:/root/.aws \
		s3-demo1


.PHONY: deploy-ecr-s3-demo1-image
deploy-ecr-s3-demo1-image: REPOSITORY_NAME = s3-demo1
deploy-ecr-s3-demo1-image: REGION = ap-northeast-1
deploy-ecr-s3-demo1-image: REGISTRY = 562435487773.dkr.ecr.$(REGION).amazonaws.com
deploy-ecr-s3-demo1-image:
	$(MAKE) awscli ARG="ecr describe-repositories --repository-names $(REPOSITORY_NAME) --output json"
	@docker image tag s3-demo1 $(REGISTRY)/$(REPOSITORY_NAME)
	@docker image ls | grep s3-demo1
	$(MAKE) awscli ARG="ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(REGISTRY)"
	@docker image push $(REGISTRY)/$(REPOSITORY_NAME)
	@docker image push $(REGISTRY)/$(REPOSITORY_NAME)
	$(MAKE) awscli ARG="ecr list-images --repository-name $(REPOSITORY_NAME)"


.PHONY: codepilot
codepilot:
	@docker container run -it --rm \
		-v $(BASE_PATH)/aws/config:/root/.aws \
		-v $(BASE_PATH)/$(APP):/app \
		-e AWS_SDK_LOAD_CONFIG=1 \
		-e AWS_PROFILE=default \
		codepilot:latest $(ARG)

.PHONY: awscli
awscli:
	@docker container run -it --rm \
		-v $(BASE_PATH)/aws/config:/root/.aws \
		amazon/aws-cli:$(AWS_CLI_VERSION) \
			$(ARG)
