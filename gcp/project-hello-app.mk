HELLO_APP_PROJECT_ID	:= multicloud-architect-b5e6e149
HELLO_APP_SRC			:= $(BASE_PATH)/gcp/hello-app
HELLO_APP_IMG			:= hello-app
HELLO_APP_IMG_TAG 		:= 2.0.1


.PHONY: hello-app-gcloud-authenticate
hello-app-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=hello-app \
		PROJECT_ID=$(HELLO_APP_PROJECT_ID)

.PHONY: hello-app-kubectl-context
hello-app-kubectl-context: REGION := asia-northeast1
hello-app-kubectl-context: CLUSTER_NAME := simple-regional-cluster-6db5
hello-app-kubectl-context:
	@$(MAKE) gcloud-sdk CMD="gcloud container clusters get-credentials --region $(REGION) $(CLUSTER_NAME)"

.PHONY: hello-app-build-image
hello-app-build-image:
	cd $(HELLO_APP_SRC) && \
		docker image build -t \
		$(HELLO_APP_IMG):$(HELLO_APP_IMG_TAG) .

.PHONY: hello-app-test-image
hello-app-test-image: PORT := 8080
hello-app-test-image: hello-app-build-image
	docker container run \
		--rm -it \
		-e PORT=$(PORT) \
		-p $(PORT):$(PORT) \
		$(HELLO_APP_IMG):$(HELLO_APP_IMG_TAG)

.PHONY: hello-app-push-image
hello-app-push-image: hello-app-build-image
	docker image tag \
		$(HELLO_APP_IMG):$(HELLO_APP_IMG_TAG) \
		$(ARTIFACT_REPOSITORY_REGION)-docker.pkg.dev/$(HELLO_APP_PROJECT_ID)/$(ARTIFACT_REPOSITORY_NAME)/$(HELLO_APP_IMG):$(HELLO_APP_IMG_TAG)
	docker image push $(ARTIFACT_REPOSITORY_REGION)-docker.pkg.dev/$(HELLO_APP_PROJECT_ID)/$(ARTIFACT_REPOSITORY_NAME)/$(HELLO_APP_IMG):$(HELLO_APP_IMG_TAG)

.PHONY: hello-app-deploy
hello-app-deploy:
	$(MAKE) hello-app-kubectl CMD="kubectl apply -f /manifests/deployment.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl apply -f /manifests/service-load-balancer.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl apply -f /manifests/hpa.yaml"

.PHONY: hello-app-deploy-ingress
hello-app-deploy-ingress:
	$(MAKE) hello-app-kubectl CMD="kubectl apply -f /manifests/deployment.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl apply -f /manifests/deployment.v2.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl apply -f /manifests/ingress-based-fanout/backend-config.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl apply -f /manifests/ingress-based-fanout/service.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl apply -f /manifests/ingress-based-fanout/service.v2.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl apply -f /manifests/ingress-based-fanout/ingress.yaml"

.PHONY: hello-app-delete-ingress
hello-app-delete-ingress:
	$(MAKE) hello-app-kubectl CMD="kubectl delete -f /manifests/ingress-based-fanout/ingress.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl delete -f /manifests/ingress-based-fanout/service.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl delete -f /manifests/ingress-based-fanout/service.v2.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl delete -f /manifests/ingress-based-fanout/backend-config.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl delete -f /manifests/deployment.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl delete -f /manifests/deployment.v2.yaml"

.PHONY: hello-app-delete
hello-app-delete:
	$(MAKE) hello-app-kubectl CMD="kubectl delete -f /manifests/service-load-balancer.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl delete -f /manifests/hpa.yaml"
	$(MAKE) hello-app-kubectl CMD="kubectl delete -f /manifests/deployment.yaml"


.PHONY: hello-app-kubectl
hello-app-kubectl:
	$(MAKE) gcloud-sdk ADDITIONAL_VOLUMES="-v $(HELLO_APP_SRC)/manifests:/manifests"
