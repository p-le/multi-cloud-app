BOOKSTORE_PROJECT_ID	:= multicloud-architect-b5e6e149
BOOKSTORE_CLIENT_SRC	:= $(BASE_PATH)/gcp/cloudrun/bookstore-client
BOOKSTORE_CLIENT_IMG	:= bookstore-client
BOOKSTORE_CLIENT_IMG_TAG := 1.0.2
BOOKSTORE_SERVER_SRC	:= $(BASE_PATH)/gcp/cloudrun/bookstore-server
BOOKSTORE_SERVER_IMG	:= bookstore-server
BOOKSTORE_SERVER_IMG_TAG := 1.0.1
BOOKSTORE_GATEWAY_SRC	:= $(BASE_PATH)/gcp/cloudrun/bookstore-gateway
BOOKSTORE_GATEWAY_IMG	:= bookstore-gateway
BOOKSTORE_GATEWAY_IMG_TAG := 1.0.0

.PHONY: bookstore-gcloud-authenticate
bookstore-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=bookstore \
		PROJECT_ID=$(BOOKSTORE_PROJECT_ID)

.PHONY: bookstore-artifact-registry-authenticate
bookstore-artifact-registry-authenticate:
	@$(MAKE) gcloud-authenticate-artifact-registry \
		PROJECT_ID=$(BOOKSTORE_PROJECT_ID) \
		HOSTNAMES=asia-northeast1-docker.pkg.dev

.PHONE: bookstore-setup
bookstore-setup:
	cp -R $(BASE_PATH)/grpc/bookstore/generated_pb2/*.py $(BOOKSTORE_CLIENT_SRC)/
	cp -R $(BASE_PATH)/grpc/bookstore/generated_pb2/*.py $(BOOKSTORE_SERVER_SRC)/

.PHONE: bookstore-build-client-image
bookstore-build-client-image:
	cd $(BOOKSTORE_CLIENT_SRC) && \
		docker image build -t \
		$(BOOKSTORE_CLIENT_IMG):$(BOOKSTORE_CLIENT_IMG_TAG) .

.PHONE: bookstore-build-server-image
bookstore-build-server-image:
	cd $(BOOKSTORE_SERVER_SRC) && \
		docker image build -t \
		$(BOOKSTORE_SERVER_IMG):$(BOOKSTORE_SERVER_IMG_TAG) .

.PHONE: bookstore-build-gateway-image
bookstore-build-gateway-image:
	$(eval BOOKSTORE_ENDPOINT_SERVICE_NAME := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints services list" | grep bookstore))
	$(eval BOOKSTORE_ENDPOINT_CONFIG_ID := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints configs list --service=${BOOKSTORE_ENDPOINT_SERVICE_NAME} --limit 1 --format=\"value(id.scope())\""))
	cd $(BOOKSTORE_GATEWAY_SRC) && \
		docker image build -t \
		$(BOOKSTORE_GATEWAY_IMG):$(BOOKSTORE_ENDPOINT_SERVICE_NAME)-$(BOOKSTORE_ENDPOINT_CONFIG_ID)-$(BOOKSTORE_GATEWAY_IMG_TAG) .


.PHONE: bookstore-test-server-image
bookstore-test-server-image: PORT := 50051
bookstore-test-server-image:
	docker container run --rm -it \
		-p $(PORT):$(PORT) \
		--net=bookstore \
		--name bookstore-server \
		$(BOOKSTORE_SERVER_IMG):$(BOOKSTORE_SERVER_IMG_TAG)



.PHONE: bookstore-test-client-image
bookstore-test-client-image: GATEWAY_HOST := bookstore-gateway-8fb0-duw6v5yogq-an.a.run.app
bookstore-test-client-image:
	openssl s_client -showcerts -connect $(GATEWAY_HOST):443 </dev/null 2>/dev/null | openssl x509 -outform PEM > miscs/ssl/gateway.pem
	docker container run --rm -it \
		-v $(BASE_PATH)/miscs/ssl/gateway.pem:/app/gateway.pem \
		--net=bookstore \
		--name bookstore-client \
		$(BOOKSTORE_CLIENT_IMG):$(BOOKSTORE_CLIENT_IMG_TAG) \
			--host bookstore-gateway-8fb0-duw6v5yogq-an.a.run.app \
			--ca_path /app/gateway.pem \
			--port 443 \
			--use_tls true




.PHONE: bookstore-push-server-image
bookstore-push-server-image: bookstore-build-server-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(BOOKSTORE_PROJECT_ID)
	docker image tag \
		$(BOOKSTORE_SERVER_IMG):$(BOOKSTORE_SERVER_IMG_TAG) \
		asia-northeast1-docker.pkg.dev/$(BOOKSTORE_PROJECT_ID)/bookstore/$(BOOKSTORE_SERVER_IMG):$(BOOKSTORE_SERVER_IMG_TAG)
	docker image push asia-northeast1-docker.pkg.dev/$(BOOKSTORE_PROJECT_ID)/bookstore/$(BOOKSTORE_SERVER_IMG):$(BOOKSTORE_SERVER_IMG_TAG)



.PHONE: bookstore-push-client-image
bookstore-push-client-image: bookstore-build-client-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(BOOKSTORE_PROJECT_ID)
	docker image tag \
		$(BOOKSTORE_CLIENT_IMG):$(BOOKSTORE_CLIENT_IMG_TAG) \
		asia-northeast1-docker.pkg.dev/$(BOOKSTORE_PROJECT_ID)/bookstore/$(BOOKSTORE_CLIENT_IMG):$(BOOKSTORE_CLIENT_IMG_TAG)
	docker image push asia-northeast1-docker.pkg.dev/$(BOOKSTORE_PROJECT_ID)/bookstore/$(BOOKSTORE_CLIENT_IMG):$(BOOKSTORE_CLIENT_IMG_TAG)



.PHONE: bookstore-push-gateway-image
bookstore-push-gateway-image: bookstore-build-gateway-image
	$(eval BOOKSTORE_ENDPOINT_SERVICE_NAME := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints services list" | grep bookstore))
	$(eval BOOKSTORE_ENDPOINT_CONFIG_ID := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints configs list --service=${BOOKSTORE_ENDPOINT_SERVICE_NAME} --limit 1 --format=\"value(id.scope())\""))
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(BOOKSTORE_PROJECT_ID)
	docker image tag \
		$(BOOKSTORE_GATEWAY_IMG):$(BOOKSTORE_ENDPOINT_SERVICE_NAME)-$(BOOKSTORE_ENDPOINT_CONFIG_ID)-$(BOOKSTORE_GATEWAY_IMG_TAG) \
		asia-northeast1-docker.pkg.dev/$(BOOKSTORE_PROJECT_ID)/bookstore/$(BOOKSTORE_GATEWAY_IMG):$(BOOKSTORE_ENDPOINT_SERVICE_NAME)-$(BOOKSTORE_ENDPOINT_CONFIG_ID)-$(BOOKSTORE_GATEWAY_IMG_TAG)
	docker image push asia-northeast1-docker.pkg.dev/$(BOOKSTORE_PROJECT_ID)/bookstore/$(BOOKSTORE_GATEWAY_IMG):$(BOOKSTORE_ENDPOINT_SERVICE_NAME)-$(BOOKSTORE_ENDPOINT_CONFIG_ID)-$(BOOKSTORE_GATEWAY_IMG_TAG)



.PHONE: bookstore-download-endpoint-service-config
bookstore-download-endpoint-service-config:
	$(eval BOOKSTORE_ENDPOINT_SERVICE_NAME := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints services list" | grep bookstore))
	$(eval BOOKSTORE_ENDPOINT_CONFIG_ID := $(shell $(MAKE) gcloud-sdk CMD="gcloud endpoints configs list --service=${BOOKSTORE_ENDPOINT_SERVICE_NAME} --limit 1 --format=\"value(id.scope())\""))

	$(MAKE) gcloud-activate-configuration PROJECT_ID=$(BOOKSTORE_PROJECT_ID)
	$(MAKE) gcloud-sdk CMD="gcloud  \
		endpoints configs describe \
		$(BOOKSTORE_ENDPOINT_CONFIG_ID) \
		--service $(BOOKSTORE_ENDPOINT_SERVICE_NAME) \
		--format json" | grep -v make > $(BOOKSTORE_GATEWAY_SRC)/service.json


.PHONE: bookstore-create-network
bookstore-create-network:
	docker network create bookstore
