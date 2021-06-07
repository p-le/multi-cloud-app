WORKFLOW_PROJECT_ID	:= multicloud-architect-b5e6e149
WORKFLOW_RANDOMGEN_SRC	:= $(BASE_PATH)/gcp/cloudrun/workflow/functions/randomgen
WORKFLOW_RANDOMGEN_TAG	:= 1.0.2
WORKFLOW_MULTIPLY_SRC	:= $(BASE_PATH)/gcp/cloudrun/workflow/functions/multiply
WORKFLOW_MULTIPLY_TAG	:= 1.0.0
WORKFLOW_FLOOR_SRC	:= $(BASE_PATH)/gcp/cloudrun/workflow/services/floor
WORKFLOW_FLOOR_IMG	:= floor
WORKFLOW_FLOOR_TAG	:= 1.0.0


.PHONY: workflow-gcloud-authenticate
workflow-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=workflow \
		PROJECT_ID=$(WORKFLOW_PROJECT_ID)


.PHONY: workflow-artifact-registry-authenticate
workflow-artifact-registry-authenticate:
	@$(MAKE) gcloud-authenticate-artifact-registry \
		PROJECT_ID=$(WORKFLOW_PROJECT_ID) \
		HOSTNAMES=asia-northeast1-docker.pkg.dev


.PHONY: workflow-archive-functions
workflow-archive-functions:
	cd $(WORKFLOW_RANDOMGEN_SRC) && \
		zip -r dist/randomgen-$(WORKFLOW_RANDOMGEN_TAG).zip main.py requirements.txt
	cd $(WORKFLOW_MULTIPLY_SRC) && \
		zip -r dist/multiply-$(WORKFLOW_MULTIPLY_TAG).zip main.py requirements.txt


.PHONY: workflow-upload-functions
workflow-upload-functions: BUCKET := workflow-functions
workflow-upload-functions:
	@$(MAKE) gcloud-sdk CMD="gsutil cp /dist/randomgen-$(WORKFLOW_RANDOMGEN_TAG).zip gs://$(BUCKET)" \
		ADDITIONAL_VOLUMES="-v $(WORKFLOW_RANDOMGEN_SRC)/dist:/dist"
	@$(MAKE) gcloud-sdk CMD="gsutil cp /dist/multiply-$(WORKFLOW_MULTIPLY_TAG).zip gs://$(BUCKET)" \
		ADDITIONAL_VOLUMES="-v $(WORKFLOW_MULTIPLY_SRC)/dist:/dist"


.PHONY: workflow-build-floor-image
workflow-build-floor-image:
	cd $(WORKFLOW_FLOOR_SRC) && \
		docker image build -t \
		$(WORKFLOW_FLOOR_IMG):$(WORKFLOW_FLOOR_TAG) .


.PHONY: workflow-test-floor-image
workflow-test-floor-image: PORT := 8080
workflow-test-floor-image: workflow-build-floor-image
	@cd $(WORKFLOW_FLOOR_SRC) && \
		docker container run \
			--rm -it \
			-e PORT=$(PORT) \
			-p $(PORT):$(PORT) \
			$(WORKFLOW_FLOOR_IMG):$(WORKFLOW_FLOOR_TAG)


.PHONY: workflow-push-floor-image
workflow-push-floor-image: workflow-build-floor-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(WORKFLOW_PROJECT_ID)
	docker image tag \
		$(WORKFLOW_FLOOR_IMG):$(WORKFLOW_FLOOR_TAG) \
		asia-northeast1-docker.pkg.dev/$(WORKFLOW_PROJECT_ID)/workflow/$(WORKFLOW_FLOOR_IMG):$(WORKFLOW_FLOOR_TAG)
	docker image push asia-northeast1-docker.pkg.dev/$(WORKFLOW_PROJECT_ID)/workflow/$(WORKFLOW_FLOOR_IMG):$(WORKFLOW_FLOOR_TAG)
