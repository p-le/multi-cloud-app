PUBSUB_APP_PROJECT_ID	:= multicloud-architect-b5e6e149
PUBSUB_APP_MESSAGE_FETCHER_SRC := $(BASE_PATH)/gcp/pubsub-app/message-fetcher
PUBSUB_APP_MESSAGE_FETCHER_IMG := pubsub-message-fetcher
PUBSUB_APP_MESSAGE_FETCHER_TAG := 1.0.5

.PHONY: pubsub-app-gcloud-authenticate
pubsub-app-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=pubsub-app \
		PROJECT_ID=$(PUBSUB_APP_PROJECT_ID)


.PHONY: pubsub-app-artifact-registry-authenticate
pubsub-app-artifact-registry-authenticate:
	@$(MAKE) gcloud-authenticate-artifact-registry \
		PROJECT_ID=$(PUBSUB_APP_PROJECT_ID) \
		HOSTNAMES=asia-northeast1-docker.pkg.dev


.PHONY: pubsub-message-fetcher-build-image
pubsub-message-fetcher-build-image:
	cd $(PUBSUB_APP_MESSAGE_FETCHER_SRC) && \
		docker image build -t \
		$(PUBSUB_APP_MESSAGE_FETCHER_IMG):$(PUBSUB_APP_MESSAGE_FETCHER_TAG) .


.PHONY: pubsub-message-fetcher-test-image
pubsub-message-fetcher-test-image: pubsub-message-fetcher-build-image
	docker container run \
		--rm -it \
		-e PUBSUB_EMULATOR_HOST=127.0.0.1:8085 \
		-e PUBSUB_PROJECT_ID=$(PUBSUB_APP_PROJECT_ID) \
		-e PUBSUB_SUBSCRIPTION=test-subcription \
		--name $(PUBSUB_APP_MESSAGE_FETCHER_IMG) \
		$(PUBSUB_APP_MESSAGE_FETCHER_IMG):$(PUBSUB_APP_MESSAGE_FETCHER_TAG)

.PHONY: pubsub-emulator
pubsub-emulator: PORT := 8085
pubsub-emulator:
	@$(MAKE) gcloud-sdk CMD="\
		gcloud beta emulators pubsub start \
			--project=$(PUBSUB_APP_PROJECT_ID) \
			--host-port=0.0.0.0:$(PORT)"

.PHONY: pubsub-message-fetcher-push-image
pubsub-message-fetcher-push-image: pubsub-message-fetcher-build-image
	@docker image tag \
		$(PUBSUB_APP_MESSAGE_FETCHER_IMG):$(PUBSUB_APP_MESSAGE_FETCHER_TAG) \
		asia-northeast1-docker.pkg.dev/$(PUBSUB_APP_PROJECT_ID)/$(ARTIFACT_REPOSITORY_NAME)/$(PUBSUB_APP_MESSAGE_FETCHER_IMG):$(PUBSUB_APP_MESSAGE_FETCHER_TAG)
	docker image push asia-northeast1-docker.pkg.dev/$(PUBSUB_APP_PROJECT_ID)/$(ARTIFACT_REPOSITORY_NAME)/$(PUBSUB_APP_MESSAGE_FETCHER_IMG):$(PUBSUB_APP_MESSAGE_FETCHER_TAG)


.PHONY: pubsub-message-fetcher-deploy
pubsub-message-fetcher-deploy:
	@$(MAKE) pubsub-kubectl CMD="kubectl apply -f /$(PUBSUB_APP_MESSAGE_FETCHER_IMG)/manifests/deployment.yaml"

.PHONY: pubsub-message-fetcher-destroy
pubsub-message-fetcher-destroy:
	@$(MAKE) pubsub-kubectl CMD="kubectl delete -f /$(PUBSUB_APP_MESSAGE_FETCHER_IMG)/manifests/deployment.yaml"


.PHONY: pubsub-kubectl
pubsub-kubectl:
	@$(MAKE) gcloud-sdk ADDITIONAL_VOLUMES="\
		-v $(PUBSUB_APP_MESSAGE_FETCHER_SRC)/manifests:/$(PUBSUB_APP_MESSAGE_FETCHER_IMG)/manifests"
