VIET_OCR_STAGE_PROJECT_ID	:= viet-ocr-stage-8650711b
VIET_OCR_STAGE_PROJECT_NAME	:= viet-ocr-stage

VIET_OCR_IMAGE_NAME			:= viet-ocr
VIET_OCR_IMAGE_TAG			:= 1.0.0
VIET_OCR_ARTIFACT_IMAGE_TAG	:= 1.0.0

VIET_OCR_ESPv2_IMAGE_NAME	:= viet-ocr-espv2
VIET_OCR_ESPv2_IMAGE_TAG	:= 1.0.0
VIET_OCR_ESPv2_ARTIFACT_IMAGE_TAG	:= 1.0.0

VIET_OCR_BACKEND_IMAGE_NAME	:= viet-ocr-backend
VIET_OCR_BACKEND_IMAGE_TAG	:= 1.0.0
VIET_OCR_BACKEND_ARTIFACT_IMAGE_TAG	:= 1.0.0

VIET_OCR_ARTIFACT_REPO		:= $(addsuffix -repository, $(VIET_OCR_STAGE_PROJECT_NAME))
TOKYO_REPOSITORY_HOSTNAME	:= asia-northeast1-docker.pkg.dev

.PHONY: gcloud-authenticate-$(VIET_OCR_STAGE_PROJECT_NAME)
gcloud-authenticate-$(VIET_OCR_STAGE_PROJECT_NAME):
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=$(VIET_OCR_STAGE_PROJECT_NAME) \
		PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)

.PHONY: gcloud-authenticate-artifact-registry-$(VIET_OCR_STAGE_PROJECT_NAME)
gcloud-authenticate-artifact-registry-$(VIET_OCR_STAGE_PROJECT_NAME):
	@$(MAKE) gcloud-authenticate-artifact-registry \
		PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID) \
		HOSTNAMES=$(TOKYO_REPOSITORY_HOSTNAME)

.PHONE: gcloud-list-artifact-images-$(VIET_OCR_STAGE_PROJECT_NAME)
gcloud-list-artifact-images-$(VIET_OCR_STAGE_PROJECT_NAME):
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)
	@$(MAKE) gcloud-sdk ARG="artifacts docker images list $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_IMAGE_NAME) --include-tags"
	@$(MAKE) gcloud-sdk ARG="artifacts docker images list $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_ESPv2_IMAGE_NAME) --include-tags"

.PHONE: gcloud-push-artifact-image-$(VIET_OCR_IMAGE_NAME)
gcloud-push-artifact-image-$(VIET_OCR_IMAGE_NAME): build-viet-ocr-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)
	docker image tag \
		$(VIET_OCR_IMAGE_NAME):$(VIET_OCR_IMAGE_TAG) \
		$(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_IMAGE_NAME):$(VIET_OCR_ARTIFACT_IMAGE_TAG)
	docker image push $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_IMAGE_NAME):$(VIET_OCR_ARTIFACT_IMAGE_TAG)

.PHONE: gcloud-cloudrun-deploy-$(VIET_OCR_STAGE_PROJECT_NAME)
gcloud-cloudrun-deploy-$(VIET_OCR_STAGE_PROJECT_NAME):
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)
	@$(MAKE) gcloud-sdk ARG="run deploy \
		--image $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_IMAGE_NAME):$(VIET_OCR_ARTIFACT_IMAGE_TAG) \
		--platform managed"


.PHONE: gcloud-push-artifact-image-$(VIET_OCR_ESPv2_IMAGE_NAME)
gcloud-push-artifact-image-$(VIET_OCR_ESPv2_IMAGE_NAME): viet-ocr-build-espv2-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)
	docker image tag \
		$(VIET_OCR_ESPv2_IMAGE_NAME):$(VIET_OCR_ESPv2_IMAGE_TAG) \
		$(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_ESPv2_IMAGE_NAME):$(VIET_OCR_ESPv2_ARTIFACT_IMAGE_TAG)
	docker image push $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_ESPv2_IMAGE_NAME):$(VIET_OCR_ESPv2_ARTIFACT_IMAGE_TAG)


.PHONE: gcloud-push-artifact-image-$(VIET_OCR_BACKEND_IMAGE_NAME)
gcloud-push-artifact-image-$(VIET_OCR_BACKEND_IMAGE_NAME): viet-ocr-build-backend-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(VIET_OCR_STAGE_PROJECT_ID)
	docker image tag \
		$(VIET_OCR_BACKEND_IMAGE_NAME):$(VIET_OCR_BACKEND_IMAGE_TAG) \
		$(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_BACKEND_IMAGE_NAME):$(VIET_OCR_BACKEND_ARTIFACT_IMAGE_TAG)
	docker image push $(TOKYO_REPOSITORY_HOSTNAME)/$(VIET_OCR_STAGE_PROJECT_ID)/$(VIET_OCR_ARTIFACT_REPO)/$(VIET_OCR_BACKEND_IMAGE_NAME):$(VIET_OCR_BACKEND_ARTIFACT_IMAGE_TAG)


.PHONE: build-viet-ocr-image
build-viet-ocr-image:
	cd gcp/cloudrun/viet_ocr && \
		docker image build -t \
		$(VIET_OCR_IMAGE_NAME):$(VIET_OCR_IMAGE_TAG) .


.PHONE: viet-ocr-build-espv2-image
viet-ocr-build-espv2-image:
	cd gcp/cloudrun/viet-ocr-ESPv2 && \
		docker image build -t \
		$(VIET_OCR_ESPv2_IMAGE_NAME):$(VIET_OCR_ESPv2_IMAGE_TAG) .

.PHONE: viet-ocr-build-backend-image
viet-ocr-build-backend-image:
	cd gcp/cloudrun/viet-ocr-backend && \
		docker image build -t \
		$(VIET_OCR_BACKEND_IMAGE_NAME):$(VIET_OCR_BACKEND_IMAGE_TAG) .

.PHONE: viet-ocr-test-espv2-image
viet-ocr-test-espv2-image: PORT := 50051
viet-ocr-test-espv2-image:
	docker container run --rm -it \
		-e PORT=$(PORT) \
		-p $(PORT):$(PORT) \
		--net=viet-ocr \
		--name viet-ocr-espv2 \
		$(VIET_OCR_ESPv2_IMAGE_NAME):$(VIET_OCR_ESPv2_IMAGE_TAG)

.PHONE: viet-ocr-test-backend-image
viet-ocr-test-backend-image: HOST := viet-ocr-espv2:50051
viet-ocr-test-backend-image:
	docker container run --rm -it \
		-e HOST=$(HOST) \
		-e API_KEY=viet-ocr \
		--net=viet-ocr \
		--name viet-ocr-backend \
		$(VIET_OCR_BACKEND_IMAGE_NAME):$(VIET_OCR_BACKEND_IMAGE_TAG)

.PHONE: viet-ocr-network
viet-ocr-network:
	docker network create viet-ocr
