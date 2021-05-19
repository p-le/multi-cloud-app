


.PHONY: gcloud-generate-terraform-key
gcloud-generate-terraform-key:
	@$(MAKE) gcloud-sdk ARG="iam service-accounts keys create /gcloud/credentials/terraform-key.json --iam-account=provisioner-terraform@multicloud-313515.iam.gserviceaccount.com"

.PHONE: gcloud-sdk
gcloud-sdk:
	@docker container run -it --rm \
		-v $(BASE_PATH)/miscs/gcp/config:/gcloud/config \
		-v $(BASE_PATH)/miscs/gcp/credentials:/gcloud/credentials \
		$(ADDITIONAL_VOLUMES) \
		-e CLOUDSDK_CONFIG=/gcloud/config \
		google/cloud-sdk:$(GCLOUD_SDK_VERSION) \
		gcloud $(ARG)

.PHONY: gcloud-activate-configuration
gcloud-activate-configuration:
	@$(MAKE) gcloud-sdk ARG="config set project $(PROJECT_ID)"

.PHONY: gcloud-authenticate
gcloud-authenticate:
	@$(MAKE) gcloud-sdk ARG="config configurations create $(CONFIGURATION_NAME)" || true
	@$(MAKE) gcloud-sdk ARG="auth login"
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(PROJECT_ID)

.PHONY: gcloud-configurations
gcloud-configurations:
	@$(MAKE) gcloud-sdk ARG="config configurations list"

.PHONY: gcloud-authenticate-artifact-registry
gcloud-authenticate-artifact-registry:
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(PROJECT_ID)
	@$(MAKE) gcloud-sdk ARG="auth configure-docker $(HOSTNAMES)" ADDITIONAL_VOLUMES="-v $(HOME)/.docker:/root/.docker"
	sudo chmod -R $(USER):$(USER) $(HOME)/.docker

include $(BASE_PATH)/gcp/build-image.mk
include $(BASE_PATH)/gcp/project-viet-ocr.mk
include $(BASE_PATH)/gcp/project-bookstore.mk
include $(BASE_PATH)/gcp/project-idp-sql.mk
