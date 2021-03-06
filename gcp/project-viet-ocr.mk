VIET_OCR_STAGE_PROJECT_ID	:= viet-ocr-stage-8650711b
VIET_OCR_STAGE_PROJECT_NAME	:= viet-ocr-stage

VIET_OCR_IMAGE_NAME			:= viet-ocr
VIET_OCR_IMAGE_TAG			:= 1.0.0
VIET_OCR_ARTIFACT_IMAGE_TAG	:= 1.0.0

VIET_OCR_ESPv2_IMAGE_NAME	:= viet-ocr-espv2
VIET_OCR_ESPv2_IMAGE_TAG	:= 1.0.2
VIET_OCR_ESPv2_ARTIFACT_IMAGE_TAG	:= 1.0.2

VIET_OCR_BACKEND_IMAGE_NAME	:= viet-ocr-backend
VIET_OCR_BACKEND_IMAGE_TAG	:= 1.0.0
VIET_OCR_BACKEND_ARTIFACT_IMAGE_TAG	:= 1.0.0

VIET_OCR_API_GATEWAY_CONFIG_ID	 := 2021-05-17r0
VIET_OCR_API_GATEWAY_IMAGE_NAME	:= viet-ocr-api-gateway

VIET_OCR_ARTIFACT_REPO		:= $(addsuffix -repository, $(VIET_OCR_STAGE_PROJECT_NAME))
TOKYO_REPOSITORY_HOSTNAME	:= asia-northeast1-docker.pkg.dev

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-gcloud-authenticate
$(VIET_OCR_STAGE_PROJECT_NAME)-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=$(VIET_OCR_STAGE_PROJECT_NAME) \
		PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-artifact-registry-authenticate
$(VIET_OCR_STAGE_PROJECT_NAME)-artifact-registry-authenticate:
	@$(MAKE) gcloud-authenticate-artifact-registry \
		PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID) \
		HOSTNAMES=$(TOKYO_REPOSITORY_HOSTNAME)

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-list-artifact-images
$(VIET_OCR_STAGE_PROJECT_NAME)-list-artifact-images:
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)
	@$(MAKE) gcloud-sdk CMD="gcloud artifacts docker images list $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_IMAGE_NAME) --include-tags"
	@$(MAKE) gcloud-sdk CMD="gcloud artifacts docker images list $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_ESPv2_IMAGE_NAME) --include-tags"

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-push-$(VIET_OCR_IMAGE_NAME)-image
$(VIET_OCR_STAGE_PROJECT_NAME)-push-$(VIET_OCR_IMAGE_NAME)-image: $(VIET_OCR_STAGE_PROJECT_NAME)-build-$(VIET_OCR_IMAGE_NAME)-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)
	docker image tag \
		$(VIET_OCR_IMAGE_NAME):$(VIET_OCR_IMAGE_TAG) \
		$(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_IMAGE_NAME):$(VIET_OCR_ARTIFACT_IMAGE_TAG)
	docker image push $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_IMAGE_NAME):$(VIET_OCR_ARTIFACT_IMAGE_TAG)

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-push-$(VIET_OCR_ESPv2_IMAGE_NAME)-image
$(VIET_OCR_STAGE_PROJECT_NAME)-push-$(VIET_OCR_ESPv2_IMAGE_NAME)-image: viet-ocr-build-espv2-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)
	docker image tag \
		$(VIET_OCR_ESPv2_IMAGE_NAME):$(VIET_OCR_ESPv2_IMAGE_TAG) \
		$(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_ESPv2_IMAGE_NAME):$(VIET_OCR_ESPv2_ARTIFACT_IMAGE_TAG)
	docker image push $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_ESPv2_IMAGE_NAME):$(VIET_OCR_ESPv2_ARTIFACT_IMAGE_TAG)


.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-push-$(VIET_OCR_BACKEND_IMAGE_NAME)-image
$(VIET_OCR_STAGE_PROJECT_NAME)-push-$(VIET_OCR_BACKEND_IMAGE_NAME)-image: viet-ocr-build-backend-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)
	docker image tag \
		$(VIET_OCR_BACKEND_IMAGE_NAME):$(VIET_OCR_BACKEND_IMAGE_TAG) \
		$(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_BACKEND_IMAGE_NAME):$(VIET_OCR_BACKEND_ARTIFACT_IMAGE_TAG)
	docker image push $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_BACKEND_IMAGE_NAME):$(VIET_OCR_BACKEND_ARTIFACT_IMAGE_TAG)


.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-build-$(VIET_OCR_IMAGE_NAME)-image
$(VIET_OCR_STAGE_PROJECT_NAME)-build-$(VIET_OCR_IMAGE_NAME)-image:
	cd gcp/cloudrun/viet_ocr && \
		docker image build -t \
		$(VIET_OCR_IMAGE_NAME):$(VIET_OCR_IMAGE_TAG) .


.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-build-$(VIET_OCR_ESPv2_IMAGE_NAME)-image
$(VIET_OCR_STAGE_PROJECT_NAME)-build-$(VIET_OCR_ESPv2_IMAGE_NAME)-image:
	cd gcp/cloudrun/viet-ocr-ESPv2 && \
		docker image build -t \
		$(VIET_OCR_ESPv2_IMAGE_NAME):$(VIET_OCR_ESPv2_IMAGE_TAG) .

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-build-$(VIET_OCR_BACKEND_IMAGE_NAME)-image
$(VIET_OCR_STAGE_PROJECT_NAME)-build-$(VIET_OCR_BACKEND_IMAGE_NAME)-image:
	cd gcp/cloudrun/viet-ocr-backend && \
		docker image build -t \
		$(VIET_OCR_BACKEND_IMAGE_NAME):$(VIET_OCR_BACKEND_IMAGE_TAG) .

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-test-$(VIET_OCR_ESPv2_IMAGE_NAME)-image
$(VIET_OCR_STAGE_PROJECT_NAME)-test-$(VIET_OCR_ESPv2_IMAGE_NAME)-image: PORT := 50051
$(VIET_OCR_STAGE_PROJECT_NAME)-test-$(VIET_OCR_ESPv2_IMAGE_NAME)-image:
	docker container run --rm -it \
		-e PORT=$(PORT) \
		-p $(PORT):$(PORT) \
		--net=viet-ocr \
		--name viet-ocr-espv2 \
		$(VIET_OCR_ESPv2_IMAGE_NAME):$(VIET_OCR_ESPv2_IMAGE_TAG)

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-test-$(VIET_OCR_BACKEND_IMAGE_NAME)-image
$(VIET_OCR_STAGE_PROJECT_NAME)-test-$(VIET_OCR_BACKEND_IMAGE_NAME)-image: HOST := viet-ocr-espv2:50051
$(VIET_OCR_STAGE_PROJECT_NAME)-test-$(VIET_OCR_BACKEND_IMAGE_NAME)-image:
	docker container run --rm -it \
		-e HOST=$(HOST) \
		-e API_KEY=viet-ocr \
		--net=viet-ocr \
		--name viet-ocr-backend \
		$(VIET_OCR_BACKEND_IMAGE_NAME):$(VIET_OCR_BACKEND_IMAGE_TAG)

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-create-network
$(VIET_OCR_STAGE_PROJECT_NAME)-create-network:
	docker network create viet-ocr

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-setup
$(VIET_OCR_STAGE_PROJECT_NAME)-setup:
	cp -R $(BASE_PATH)/grpc/helloworld $(BASE_PATH)/gcp/cloudrun/viet-ocr-ESPv2/protos/helloworld
	cp -R $(BASE_PATH)/grpc/helloworld $(BASE_PATH)/gcp/cloudrun/viet-ocr-backend/protos/helloworld

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-update-$(VIET_OCR_API_GATEWAY_IMAGE_NAME)-image
$(VIET_OCR_STAGE_PROJECT_NAME)-update-$(VIET_OCR_API_GATEWAY_IMAGE_NAME)-image:
	$(eval VIET_OCR_API_GATEWAY_SERVICE_NAME := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints services list" | grep viet-ocr-espv2))
	$(eval VIET_OCR_API_GATEWAY_CONFIG_ID := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints configs list --service=${VIET_OCR_API_GATEWAY_SERVICE_NAME} --limit 1 --format=\"value(id.scope())\""))

	$(MAKE) gcloud-activate-configuration PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)
	$(MAKE) gcloud-sdk CMD="gcloud  \
		endpoints configs describe \
		$(VIET_OCR_API_GATEWAY_CONFIG_ID) \
		--service $(VIET_OCR_API_GATEWAY_SERVICE_NAME) \
		--format json" | grep -v make > $(BASE_PATH)/gcp/cloudrun/viet-ocr-api-gateway/service.json

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-build-$(VIET_OCR_API_GATEWAY_IMAGE_NAME)-image
$(VIET_OCR_STAGE_PROJECT_NAME)-build-$(VIET_OCR_API_GATEWAY_IMAGE_NAME)-image:
	$(eval VIET_OCR_API_GATEWAY_SERVICE_NAME := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints services list" | grep viet-ocr-espv2))
	$(eval VIET_OCR_API_GATEWAY_CONFIG_ID := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints configs list --service=${VIET_OCR_API_GATEWAY_SERVICE_NAME} --limit 1 --format=\"value(id.scope())\""))
	cd gcp/cloudrun/viet-ocr-api-gateway && \
		docker image build -t \
			$(VIET_OCR_API_GATEWAY_IMAGE_NAME):$(VIET_OCR_API_GATEWAY_SERVICE_NAME)-$(VIET_OCR_API_GATEWAY_CONFIG_ID) .

.PHONY: $(VIET_OCR_STAGE_PROJECT_NAME)-push-$(VIET_OCR_API_GATEWAY_IMAGE_NAME)-image
$(VIET_OCR_STAGE_PROJECT_NAME)-push-$(VIET_OCR_API_GATEWAY_IMAGE_NAME)-image: $(VIET_OCR_STAGE_PROJECT_NAME)-build-$(VIET_OCR_API_GATEWAY_IMAGE_NAME)-image
	$(eval VIET_OCR_API_GATEWAY_SERVICE_NAME := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints services list" | grep viet-ocr-espv2))
	$(eval VIET_OCR_API_GATEWAY_CONFIG_ID := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints configs list --service=${VIET_OCR_API_GATEWAY_SERVICE_NAME} --limit 1 --format=\"value(id.scope())\""))
	docker image tag \
		$(VIET_OCR_API_GATEWAY_IMAGE_NAME):$(VIET_OCR_API_GATEWAY_SERVICE_NAME)-$(VIET_OCR_API_GATEWAY_CONFIG_ID) \
		$(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_API_GATEWAY_IMAGE_NAME):$(VIET_OCR_API_GATEWAY_SERVICE_NAME)-$(VIET_OCR_API_GATEWAY_CONFIG_ID)
	docker image push $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_API_GATEWAY_IMAGE_NAME):$(VIET_OCR_API_GATEWAY_SERVICE_NAME)-$(VIET_OCR_API_GATEWAY_CONFIG_ID)
