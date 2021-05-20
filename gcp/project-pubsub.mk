PUBSUB_PROJECT_ID	:= multicloud-architect-b5e6e149
PUBSUB_SRC			:= $(BASE_PATH)/gcp/cloudrun/pubsub
PUBSUB_IMG			:= pubsub
PUBSUB_IMG_TAG 		:= 1.0.2


.PHONY: pubsub-gcloud-authenticate
pubsub-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=pubsub \
		PROJECT_ID=$(PUBSUB_PROJECT_ID)


.PHONY: pubsub-artifact-registry-authenticate
pubsub-artifact-registry-authenticate:
	@$(MAKE) gcloud-authenticate-artifact-registry \
		PROJECT_ID=$(PUBSUB_PROJECT_ID) \
		HOSTNAMES=asia-northeast1-docker.pkg.dev


.PHONE: pubsub-build-image
pubsub-build-image:
	cd $(PUBSUB_SRC) && \
		docker image build -t \
		$(PUBSUB_IMG):$(PUBSUB_IMG_TAG) .


.PHONE: pubsub-test-image
pubsub-test-image: PORT := 8080
pubsub-test-image: pubsub-build-image
	@cd $(PUBSUB_SRC) && \
		docker container run \
			--rm -it \
			--net=pubsub \
			-e PORT=$(PORT) \
			-e PUBSUB_EMULATOR_HOST=pubsub-emulator:8085 \
			-e PUBSUB_PROJECT_ID=$(PUBSUB_PROJECT_ID) \
			-p $(PORT):$(PORT) \
			--name pubsub-client \
			$(PUBSUB_IMG):$(PUBSUB_IMG_TAG)

.PHONE: pubsub-test-emulator
pubsub-test-emulator: PORT := 8085
pubsub-test-emulator:
	@docker container run \
		--rm -it \
		--net=pubsub \
		--name pubsub-emulator \
		-p $(PORT):$(PORT) \
		pubsub-emulator:$(GCLOUD_SDK_VERSION) \
			gcloud beta emulators pubsub start \
			--project=$(PUBSUB_PROJECT_ID) \
			--host-port=0.0.0.0:$(PORT)


.PHONE: pubsub-push-image
pubsub-push-image: pubsub-build-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(PUBSUB_PROJECT_ID)
	docker image tag \
		$(PUBSUB_IMG):$(PUBSUB_IMG_TAG) \
		asia-northeast1-docker.pkg.dev/$(PUBSUB_PROJECT_ID)/pubsub/$(PUBSUB_IMG):$(PUBSUB_IMG_TAG)
	docker image push asia-northeast1-docker.pkg.dev/$(PUBSUB_PROJECT_ID)/pubsub/$(PUBSUB_IMG):$(PUBSUB_IMG_TAG)


.PHONE: pubsub-create-network
pubsub-create-network:
	docker network create pubsub
