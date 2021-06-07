IMAGE_PROCESSING_PROJECT_ID	:= multicloud-architect-b5e6e149
IMAGE_PROCESSING_SRC			:= $(BASE_PATH)/gcp/cloudrun/image-processing
IMAGE_PROCESSING_IMG			:= image-processing
IMAGE_PROCESSING_IMG_TAG 		:= 1.0.1


.PHONY: image-processing-gcloud-authenticate
image-processing-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=image-processing \
		PROJECT_ID=$(IMAGE_PROCESSING_PROJECT_ID)


.PHONY: image-processing-artifact-registry-authenticate
image-processing-artifact-registry-authenticate:
	@$(MAKE) gcloud-authenticate-artifact-registry \
		PROJECT_ID=$(IMAGE_PROCESSING_PROJECT_ID) \
		HOSTNAMES=asia-northeast1-docker.pkg.dev


.PHONY: image-processing-build-image
image-processing-build-image:
	cd $(IMAGE_PROCESSING_SRC) && \
		docker image build -t \
		$(IMAGE_PROCESSING_IMG):$(IMAGE_PROCESSING_IMG_TAG) .


.PHONY: image-processing-test-image
image-processing-test-image: PORT := 8080
image-processing-test-image: image-processing-build-image
	@cd $(IMAGE_PROCESSING_SRC) && \
		docker container run \
			--rm -it \
			-e PORT=$(PORT) \
			-p $(PORT):$(PORT) \
			--name image-processing \
			$(IMAGE_PROCESSING_IMG):$(IMAGE_PROCESSING_IMG_TAG)


.PHONY: image-processing-push-image
image-processing-push-image: image-processing-build-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(IMAGE_PROCESSING_PROJECT_ID)
	docker image tag \
		$(IMAGE_PROCESSING_IMG):$(IMAGE_PROCESSING_IMG_TAG) \
		asia-northeast1-docker.pkg.dev/$(IMAGE_PROCESSING_PROJECT_ID)/image-processing/$(IMAGE_PROCESSING_IMG):$(IMAGE_PROCESSING_IMG_TAG)
	docker image push asia-northeast1-docker.pkg.dev/$(IMAGE_PROCESSING_PROJECT_ID)/image-processing/$(IMAGE_PROCESSING_IMG):$(IMAGE_PROCESSING_IMG_TAG)

.PHONY: image-processing-upload-image
image-processing-upload-image: BUCKET := image-processing-f057
image-processing-upload-image:
	@$(MAKE) gcloud-sdk CMD="gsutil cp /zombie.jpg gs://$(BUCKET)" \
		ADDITIONAL_VOLUMES="-v $(IMAGE_PROCESSING_SRC)/zombie.jpg:/zombie.jpg"
