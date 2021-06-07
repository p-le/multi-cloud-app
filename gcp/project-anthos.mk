ANTHOS_PROJECT_ID	:= multicloud-architect-b5e6e149
ANTHOS_SRC			:= $(BASE_PATH)/gcp/anthos/web-app
ANTHOS_IMG			:= wep-app
ANTHOS_IMG_TAG 		:= 1.0.0

.PHONY: anthos-kubectl-context
anthos-kubectl-context: CLUSTER_NAME := anthos-cloud-run-cluster-0e02
anthos-kubectl-context:
	@$(MAKE) gcloud-sdk CMD="gcloud container clusters get-credentials --region $(REGION) $(CLUSTER_NAME)"

.PHONY: anthos-setup
anthos-setup: REGION := asia-northeast1
anthos-setup: CLUSTER_NAME := anthos-cloud-run-cluster-df23
anthos-setup: NAMESPACE := cloud-run-services
anthos-setup:
	@$(MAKE) gcloud-sdk CMD="gcloud config set run/platform gke"
	@$(MAKE) gcloud-sdk CMD="gcloud config set run/cluster $(CLUSTER_NAME)"
	@$(MAKE) gcloud-sdk CMD="gcloud config set run/cluster_location $(REGION)"
	@$(MAKE) gcloud-sdk CMD="gcloud config set run/namespace $(NAMESPACE)"

.PHONY: anthos-deploy
anthos-deploy: IMAGE := gcr.io/knative-samples/simple-api
anthos-deploy:
	@$(MAKE) gcloud-sdk CMD="gcloud run deploy sample --image $(IMAGE)"

.PHONY: anthos-check-istio
anthos-check-istio:
	@$(MAKE) gcloud-sdk CMD="kubectl get svc istio-ingress -n gke-system"
