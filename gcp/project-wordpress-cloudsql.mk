WORDPRESS_CLOUDSQL_PROJECT_ID	:= multicloud-architect-b5e6e149
WORDPRESS_CLOUDSQL_SRC			:= $(BASE_PATH)/gcp/wordpress-cloudsql
WORDPRESS_CLOUDSQL_IMG			:= wordpress-cloudsql
WORDPRESS_CLOUDSQL_IMG_TAG 		:= 1.0.0


.PHONY: wordpress-cloudsql-gcloud-authenticate
wordpress-cloudsql-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=wordpress-cloudsql \
		PROJECT_ID=$(WORDPRESS_CLOUDSQL_PROJECT_ID)

.PHONY: wordpress-cloudsql-kubectl-context
wordpress-cloudsql-kubectl-context: REGION := asia-northeast1
wordpress-cloudsql-kubectl-context: CLUSTER_NAME := simple-regional-cluster-6db5
wordpress-cloudsql-kubectl-context:
	@$(MAKE) gcloud-sdk CMD="gcloud container clusters get-credentials --region $(REGION) $(CLUSTER_NAME)"

.PHONY: wordpress-cloudsql-deploy
wordpress-cloudsql-deploy: CLOUDSQL_USER := connector
wordpress-cloudsql-deploy: CLOUDSQL_PASSWORD := AjorL03mIrnK
wordpress-cloudsql-deploy: CLOUDSQL_CONNECTION := multicloud-architect-b5e6e149:asia-northeast1:cloud-native-a0fb
wordpress-cloudsql-deploy: CLOUDSQL_SA_SECRET_KEY := gks-sa-key
wordpress-cloudsql-deploy: CLOUDSQL_SA_SECRET_VERSION := 1
wordpress-cloudsql-deploy:
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl delete secret cloudsql-db-credentials --ignore-not-found"
	@$(MAKE) wordpress-cloudsql-kubectl CMD=" \
		kubectl create secret generic cloudsql-db-credentials \
		--from-literal DB_USER=$(CLOUDSQL_USER) \
		--from-literal DB_PASSWORD=$(CLOUDSQL_PASSWORD) \
		--from-literal DB_NAME=wordpress"
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl delete secret cloudsql-db-connection --ignore-not-found"
	@$(MAKE) wordpress-cloudsql-kubectl CMD=" \
		kubectl create secret generic cloudsql-db-connection \
		--from-literal DB_CONNECTION=$(CLOUDSQL_CONNECTION)"
	@$(MAKE) gcloud-sdk CMD="gcloud secrets versions access $(CLOUDSQL_SA_SECRET_VERSION) --secret=$(CLOUDSQL_SA_SECRET_KEY)" | grep -v "make" > $(BASE_PATH)/miscs/gcp/credentials/$(CLOUDSQL_SA_SECRET_KEY).json
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl delete secret cloudsql-sa-key --ignore-not-found"
	@$(MAKE) wordpress-cloudsql-kubectl CMD=" \
		kubectl create secret generic cloudsql-sa-key \
		--from-file /gcloud/credentials/$(CLOUDSQL_SA_SECRET_KEY).json"
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl apply -f /wordpress/volumeclaim.yaml"
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl apply -f /wordpress/deployment.yaml"
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl apply -f /wordpress/service.yaml"

.PHONY: wordpress-cloudsql-delete
wordpress-cloudsql-delete:
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl delete -f /wordpress/service.yaml"
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl delete -f /wordpress/deployment.yaml"
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl delete -f /wordpress/volumeclaim.yaml"
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl delete secret cloudsql-sa-key --ignore-not-found"
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl delete secret cloudsql-db-connection --ignore-not-found"
	@$(MAKE) wordpress-cloudsql-kubectl CMD="kubectl delete secret cloudsql-db-credentials --ignore-not-found"


.PHONY: wordpress-sa-key
wordpress-sa-key: SA_EMAIL := gks-simple-regional-beta-sa@multicloud-architect-b5e6e149.iam.gserviceaccount.com
wordpress-sa-key:
	@$(MAKE) gcloud-sdk CMD=" \
			gcloud iam service-accounts keys create \
				/gcloud/credentials/$(SA_EMAIL).json \
    			--iam-account $(SA_EMAIL)"
	@$(MAKE) gcloud-sdk CMD=" \
		gcloud secrets create gks-sa-key \
			--data-file /gcloud/credentials/$(SA_EMAIL).json"

.PHONY: wordpress-cloudsql-kubectl
wordpress-cloudsql-kubectl:
	@$(MAKE) gcloud-sdk ADDITIONAL_VOLUMES="\
		-v $(WORDPRESS_CLOUDSQL_SRC)/cloud-sql-proxy:/cloud-sql-proxy \
		-v $(WORDPRESS_CLOUDSQL_SRC)/wordpress:/wordpress"
