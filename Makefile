checksum = $(shell md5sum -b dist/dist.zip | awk '{ print $$1 }')

build:
	@cp $(GOOGLE_APPLICATION_CREDENTIALS) ./gcp_credentials.json
	@mkdir -p dist
	@zip -j dist/dist.zip lib/index.js -qq
	@zip -uj dist/dist.zip ./gcp_credentials.json -qq
	@zip -ur dist/dist.zip node_modules -qq
	@zip -j dist/custom_resource.zip etc/LambdaS3.py -qq
	@rm gcp_credentials.json

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
