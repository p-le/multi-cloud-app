.PHONE: gcloud-sdk
gcloud-sdk:
	@docker container run -it --rm \
		-v $(BASE_PATH)/miscs/gcp/config:/gcloud/config \
		-v $(BASE_PATH)/miscs/gcp/credentials:/gcloud/credentials \
		$(ADDITIONAL_VOLUMES) \
		-e CLOUDSDK_CONFIG=/gcloud/config \
		google/cloud-sdk:$(GCLOUD_SDK_VERSION) $(CMD)


.PHONY: gcloud-build-image
gcloud-build-image:
	@cd gcp/gcloud-sdk && \
		docker image build -t \
			cloud-sdk:$(GCLOUD_SDK_VERSION) \
			--build-arg GCLOUD_SDK_VERSION=$(GCLOUD_SDK_VERSION) .


.PHONY: gcloud-build-pubsub-emulator-image
gcloud-build-pubsub-emulator-image:
	@cd gcp/gcloud-sdk && \
		docker image build -t \
			pubsub-emulator:$(GCLOUD_SDK_VERSION) \
			--build-arg GCLOUD_SDK_VERSION=$(GCLOUD_SDK_VERSION) \
			-f Dockerfile.pubsub.emulator .


.PHONY: gcloud-activate-configuration
gcloud-activate-configuration:
	@$(MAKE) gcloud-sdk CMD="gcloud config set project $(PROJECT_ID)"


.PHONY: gcloud-authenticate
gcloud-authenticate:
	@$(MAKE) gcloud-sdk CMD="gcloud config configurations create $(CONFIGURATION_NAME)" || true
	@$(MAKE) gcloud-sdk CMD="gcloud auth login"
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(PROJECT_ID)


.PHONY: gcloud-authenticate-artifact-registry
gcloud-authenticate-artifact-registry:
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(PROJECT_ID)
	@$(MAKE) gcloud-sdk CMD="gcloud auth configure-docker $(HOSTNAMES)" ADDITIONAL_VOLUMES="-v $(HOME)/.docker:/root/.docker"
	sudo chmod -R $(USER):$(USER) $(HOME)/.docker


.PHONY: gcloud-configurations
gcloud-configurations:
	@$(MAKE) gcloud-sdk CMD="gcloud config configurations list"


include $(BASE_PATH)/gcp/project-viet-ocr.mk
include $(BASE_PATH)/gcp/project-bookstore.mk
include $(BASE_PATH)/gcp/project-idp-sql.mk
include $(BASE_PATH)/gcp/project-pubsub.mk
include $(BASE_PATH)/gcp/project-system-package.mk
include $(BASE_PATH)/gcp/project-workflow.mk
