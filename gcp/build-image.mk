.PHONY: build-gcloud-sdk-image
build-gcloud-sdk-image:
	@cd gcp/gcloud-sdk && \
		docker image build -t \
			cloud-sdk:$(GCLOUD_SDK_VERSION) \
			--build-arg GCLOUD_SDK_VERSION=$(GCLOUD_SDK_VERSION) \
			.
