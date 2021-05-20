IDP_SQL_PROJECT_ID	:= multicloud-architect-b5e6e149
IDP_SQL_SRC			:= $(BASE_PATH)/gcp/cloudrun/idp-sql
IDP_SQL_IMG			:= idp-sql
IDP_SQL_IMG_TAG 	:= 1.0.2
IDP_SQL_CLOUD_SQL_PROXY_SA_KEY 	:= cloud-sql-proxy-sa-key


.PHONY: idp-sql-gcloud-authenticate
idp-sql-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=idp-sql \
		PROJECT_ID=$(IDP_SQL_PROJECT_ID)


.PHONY: idp-sql-artifact-registry-authenticate
idp-sql-artifact-registry-authenticate:
	@$(MAKE) gcloud-authenticate-artifact-registry \
		PROJECT_ID=$(IDP_SQL_PROJECT_ID) \
		HOSTNAMES=asia-northeast1-docker.pkg.dev


# .PHONE: idp-sql-setup
# idp-sql-setup:
# 	cp -R $(BASE_PATH)/grpc/idp-sql/generated_pb2/*.py $(IDP_SQL_CLIENT_SRC)/
# 	cp -R $(BASE_PATH)/grpc/idp-sql/generated_pb2/*.py $(IDP_SQL_SERVER_SRC)/


.PHONE: idp-sql-build-image
idp-sql-build-image:
	cd $(IDP_SQL_SRC) && \
		docker image build -t \
		$(IDP_SQL_IMG):$(IDP_SQL_IMG_TAG) .


.PHONE: idp-sql-test-image
idp-sql-test-image: INSTANCE_CONNECTION_NAME := multicloud-architect-b5e6e149:asia-northeast1:idp-sql-instance-e99d
idp-sql-test-image: idp-sql-build-image
	@$(MAKE) gcloud-sdk CMD="gcloud secrets versions access latest --secret=$(IDP_SQL_CLOUD_SQL_PROXY_SA_KEY)" | grep -v make > $(IDP_SQL_SRC)/misc/$(addsuffix .json, $(IDP_SQL_CLOUD_SQL_PROXY_SA_KEY))
	cd $(IDP_SQL_SRC) && \
		CREDENTIAL_FILE=$(addsuffix .json, $(IDP_SQL_CLOUD_SQL_PROXY_SA_KEY)) \
		TAG=$(IDP_SQL_IMG_TAG) \
		INSTANCE_CONNECTION_NAME=${INSTANCE_CONNECTION_NAME} \
		docker-compose up --remove-orphans


.PHONE: idp-sql-push-image
idp-sql-push-image: idp-sql-build-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(IDP_SQL_PROJECT_ID)
	docker image tag \
		$(IDP_SQL_IMG):$(IDP_SQL_IMG_TAG) \
		asia-northeast1-docker.pkg.dev/$(IDP_SQL_PROJECT_ID)/idp-sql/$(IDP_SQL_IMG):$(IDP_SQL_IMG_TAG)
	docker image push asia-northeast1-docker.pkg.dev/$(IDP_SQL_PROJECT_ID)/idp-sql/$(IDP_SQL_IMG):$(IDP_SQL_IMG_TAG)
