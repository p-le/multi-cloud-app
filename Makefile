BASE_PATH			:= $(shell pwd)
AWS_CLI_VERSION 	:= 2.1.39
GCLOUD_SDK_VERSION	:= 341.0.0
KUBECTL_VERSION		:= 1.21.1

include $(BASE_PATH)/aws/Makefile
include $(BASE_PATH)/gcp/Makefile
include $(BASE_PATH)/azure/Makefile

.PHONY: submodules-sync
submodules-sync:
	git submodule sync
	git submodule update --init --recursive --remote

.PHONY: submodules-grpc-copy
submodules-grpc-copy:
	cp -r $(BASE_PATH)/grpc/viet-soccer/generated_pb2/*.py $(BASE_PATH)/gcp/viet-soccer/firestore-api/
	cp -r $(BASE_PATH)/grpc/viet-soccer/generated_pb2/*.py $(BASE_PATH)/gcp/viet-soccer/youtube-comment/
	cp -r $(BASE_PATH)/grpc/viet-soccer/generated_pb2/*.py $(BASE_PATH)/gcp/viet-soccer/youtube-upload/

.PHONY: clean
clean:
	docker rmi -f $(shell docker images -f "dangling=true" -q)
