checksum = $(shell md5sum -b dist/dist.zip | awk '{ print $$1 }')

install:
	npm install --no-progress

build: install
	mkdir -p dist
	@cp $(GOOGLE_APPLICATION_CREDENTIALS) ./dist/gcp_credentials.json
	- rm dist/dist.zip
	zip -j dist/dist.zip lib/index.js -q
	zip -uj dist/dist.zip dist/gcp_credentials.json -q
	zip -ur dist/dist.zip node_modules -q
	zip -j dist/custom_resource.zip etc/LambdaS3.py -q
	@rm dist/gcp_credentials.json

upload: build
	@aws s3 cp dist/dist.zip s3://$(LAMBDA_SOURCE_BUCKET)/$(checksum).zip
	@aws s3 cp dist/custom_resource.zip s3://$(LAMBDA_SOURCE_BUCKET)/custom_resource.zip

create: upload
	@aws cloudformation create-stack \
		--stack-name $(STACK_NAME) \
		--parameters ParameterKey=S3DataBucket,ParameterValue=$(SOURCE_BUCKET) \
								 ParameterKey=GCPBucket,ParameterValue=$(DESTINATION_BUCKET) \
								 ParameterKey=LambdaSourceBucket,ParameterValue=$(LAMBDA_SOURCE_BUCKET) \
								 ParameterKey=LambdaSourceKey,ParameterValue=$(checksum).zip \
		--template-body file://cloudformation.yaml \
		--capabilities CAPABILITY_IAM

update: upload
	@aws cloudformation update-stack \
		--stack-name $(STACK_NAME) \
		--parameters ParameterKey=S3DataBucket,ParameterValue=$(SOURCE_BUCKET) \
								 ParameterKey=GCPBucket,ParameterValue=$(DESTINATION_BUCKET) \
								 ParameterKey=LambdaSourceBucket,ParameterValue=$(LAMBDA_SOURCE_BUCKET) \
								 ParameterKey=LambdaSourceKey,ParameterValue=$(checksum).zip \
		--template-body file://cloudformation.yaml \
		--capabilities CAPABILITY_IAM
