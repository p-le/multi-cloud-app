BASE_PATH := $(shell pwd)
AWS_CLI_VERSION := 2.1.39
GCLOUD_SDK_VERSION := 340.0.0-alpine

include $(BASE_PATH)/aws/Makefile
include $(BASE_PATH)/gcp/Makefile
include $(BASE_PATH)/azure/Makefile

.PHONY: clean
clean:
	docker system prune
	docker volume prune
