DJANGO_APP_PROJECT_ID	:= multicloud-architect-b5e6e149
DJANGO_POLL_APP_SRC		:= $(BASE_PATH)/gcp/django/poll-app
DJANGO_POLL_APP_IMG		:= django-poll-app
DJANGO_POLL_APP_TAG 	:= 1.0.2


.PHONY: django-poll-app-gcloud-authenticate
django-poll-app-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=django-poll-app \
		PROJECT_ID=$(DJANGO_APP_PROJECT_ID)

.PHONY: django-poll-app-kubectl-context
django-poll-app-kubectl-context: REGION := asia-northeast1
django-poll-app-kubectl-context: CLUSTER_NAME := simple-regional-cluster-6db5
django-poll-app-kubectl-context:
	@$(MAKE) gcloud-sdk CMD="gcloud container clusters get-credentials --region $(REGION) $(CLUSTER_NAME)"

.PHONY: django-poll-app-build-image
django-poll-app-build-image:
	cd $(DJANGO_POLL_APP_SRC) && \
		docker image build -t \
		$(DJANGO_POLL_APP_IMG):$(DJANGO_POLL_APP_TAG) .

.PHONY: django-poll-app-test-image
django-poll-app-test-image: PORT := 8080
django-poll-app-test-image: django-poll-app-build-image
	cd $(DJANGO_POLL_APP_SRC) && \
		IMAGE=$(DJANGO_POLL_APP_IMG) TAG=$(DJANGO_POLL_APP_TAG) docker-compose up

.PHONY: django-poll-app-test-cmd
django-poll-app-test-cmd:
	cd $(DJANGO_POLL_APP_SRC) && \
		IMAGE=$(DJANGO_POLL_APP_IMG) TAG=$(DJANGO_POLL_APP_TAG) docker-compose exec poll-app python manage.py $(DJANGO_CMD)

.PHONY: django-poll-app-check-db
django-poll-app-check-db:
	cd $(DJANGO_POLL_APP_SRC) && \
		IMAGE=$(DJANGO_POLL_APP_IMG) TAG=$(DJANGO_POLL_APP_TAG) docker-compose exec mysql-db /bin/bash


.PHONY: django-poll-app-push-image
django-poll-app-push-image: django-poll-app-build-image
	docker image tag \
		$(DJANGO_POLL_APP_IMG):$(DJANGO_POLL_APP_TAG) \
		$(ARTIFACT_REPOSITORY_REGION)-docker.pkg.dev/$(DJANGO_APP_PROJECT_ID)/$(ARTIFACT_REPOSITORY_NAME)/$(DJANGO_POLL_APP_IMG):$(DJANGO_POLL_APP_TAG)
	docker image push $(ARTIFACT_REPOSITORY_REGION)-docker.pkg.dev/$(DJANGO_APP_PROJECT_ID)/$(ARTIFACT_REPOSITORY_NAME)/$(DJANGO_POLL_APP_IMG):$(DJANGO_POLL_APP_TAG)

.PHONY: django-poll-app-prod-migrate
django-poll-app-prod-migrate:
	@$(MAKE) gcloud-sdk CMD="kubectl exec $(POD_NAME) polls-app -- python manage.py migrate"

.PHONY: django-poll-app-deploy
django-poll-app-deploy: CLOUDSQL_USER := connector
django-poll-app-deploy: CLOUDSQL_PASSWORD_SECRET_KEY := wordpress-user-password-credential
django-poll-app-deploy: CLOUDSQL_PASSWORD_SECRET_VERSION := 1
django-poll-app-deploy: CLOUDSQL_CONNECTION_SECRET_KEY := wordpress-db-connection-credential
django-poll-app-deploy: CLOUDSQL_CONNECTION_SECRET_VERSION := 2
django-poll-app-deploy: CLOUDSQL_SA_SECRET_KEY := gks-sa-key
django-poll-app-deploy: CLOUDSQL_SA_SECRET_VERSION := 1
django-poll-app-deploy:
	$(eval CLOUDSQL_PASSWORD := $(shell $(MAKE) gcloud-sdk CMD="gcloud secrets versions access $(CLOUDSQL_PASSWORD_SECRET_VERSION) --secret=$(CLOUDSQL_PASSWORD_SECRET_KEY)" | grep -v "make"))
	$(eval CLOUDSQL_CONNECTION := $(shell $(MAKE) gcloud-sdk CMD="gcloud secrets versions access $(CLOUDSQL_CONNECTION_SECRET_VERSION) --secret=$(CLOUDSQL_CONNECTION_SECRET_KEY)" | grep -v "make"))
	$(eval SECRET_KEY := $(shell python3 -c 'import secrets; print(secrets.token_hex(100))'))
	@$(MAKE) django-poll-app-kubectl CMD="kubectl delete secret cloudsql-db-credentials --ignore-not-found"
	@$(MAKE) django-poll-app-kubectl CMD="kubectl delete secret cloudsql-db-connection --ignore-not-found"
	@$(MAKE) django-poll-app-kubectl CMD="kubectl delete secret cloudsql-sa-key --ignore-not-found"
	@$(MAKE) django-poll-app-kubectl CMD="kubectl delete secret django-secret-key --ignore-not-found"
	@$(MAKE) django-poll-app-kubectl CMD=" \
		kubectl create secret generic cloudsql-db-credentials \
		--from-literal db_user=$(CLOUDSQL_USER) \
		--from-literal db_password=$(CLOUDSQL_PASSWORD) \
		--from-literal db_name=polls"
	@$(MAKE) django-poll-app-kubectl CMD=" \
		kubectl create secret generic cloudsql-db-connection \
		--from-literal db_connection=$(CLOUDSQL_CONNECTION)"
	@$(MAKE) gcloud-sdk CMD="gcloud secrets versions access $(CLOUDSQL_SA_SECRET_VERSION) --secret=$(CLOUDSQL_SA_SECRET_KEY)" | grep -v "make" > $(BASE_PATH)/miscs/gcp/credentials/$(CLOUDSQL_SA_SECRET_KEY).json
	@$(MAKE) django-poll-app-kubectl CMD=" \
		kubectl create secret generic cloudsql-sa-key \
		--from-file /gcloud/credentials/$(CLOUDSQL_SA_SECRET_KEY).json"
	@$(MAKE) django-poll-app-kubectl CMD=" \
		kubectl create secret generic django-secret-key \
		--from-literal secret_key=$(SECRET_KEY)"
	@$(MAKE) django-poll-app-kubectl CMD="kubectl apply -f /manifests/deployment.yaml"
	@$(MAKE) django-poll-app-kubectl CMD="kubectl apply -f /manifests/service.yaml"
	@$(MAKE) django-poll-app-kubectl CMD="kubectl apply -f /manifests/frontend-configs.yaml"

.PHONY: django-poll-app-delete
django-poll-app-delete:
	@$(MAKE) django-poll-app-kubectl CMD="kubectl delete -f /manifests/service.yaml"
	@$(MAKE) django-poll-app-kubectl CMD="kubectl delete -f /manifests/deployment.yaml"
	@$(MAKE) django-poll-app-kubectl CMD="kubectl delete secret cloudsql-db-credentials --ignore-not-found"
	@$(MAKE) django-poll-app-kubectl CMD="kubectl delete secret cloudsql-db-connection --ignore-not-found"
	@$(MAKE) django-poll-app-kubectl CMD="kubectl delete secret cloudsql-sa-key --ignore-not-found"
	@$(MAKE) django-poll-app-kubectl CMD="kubectl delete secret django-secret-key --ignore-not-found"

.PHONY: django-poll-app-kubectl
django-poll-app-kubectl:
	@$(MAKE) gcloud-sdk ADDITIONAL_VOLUMES="\
		-v $(DJANGO_POLL_APP_SRC)/manifests:/manifests"
