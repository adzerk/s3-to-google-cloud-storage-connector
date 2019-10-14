# AWS S3 to GCP Storage Connector
## Overview
Currently, Adzerk supports Data Shipping to an external AWS S3 bucket that the customer controls. While this approach works for giving you access to your data, it limits you to using AWS services. As other Cloud Providers become more popular, you may want to utilize services on those platforms to store, process, and analyze your Adzerk data.

This project creates a CloudFormation Stack in your AWS account and includes everything you need to replicate the data written to your S3 bucket to a Google Cloud Storage bucket. Once everything is installed, you’ll be able to utilize Google Cloud Storage Triggers to listen for new data arriving in the bucket and execute further processing logic using Google Cloud Functions.

## Prerequisites

### Make
Make is used to package assets, upload them to S3, and execute the creation and update of the included CloudFormation templates. If you don’t have make available, you can view the Makefile and execute the steps manually.

### AWS CLI
The easiest way to execute the CloudFormation template is to install the AWS CLI if you haven’t already. You can download and install the CLI for your platform from:

https://docs.aws.amazon.com/en_pv/cli/latest/userguide/cli-chap-install.html

Once that's done, you'll need to create a S3 Bucket to hold the zipped source bundles for the Lambda functions that are being created. You can use the following command:

```bash
aws s3 mb s3://your-globablly-unique-lambda-source-bucket-name
```

### Adzerk Data Shipping
Before proceeding, you’ll need to have Data Shipping enabled and configured for your network. If you haven’t already, follow the directions found here before proceeding:

https://dev.adzerk.com/docs/data-shipping

### GCP Storage Bucket
Next, you’ll need to ensure that you have a Storage Bucket created inside your GCP instance to receive the files sent by the Connector. Once you’ve created your bucket, use the following link to create your Service Account Key. This will be the key that is used by the Connector to write files to your bucket. Be sure to use the JSON format.

https://console.cloud.google.com/apis/credentials/serviceaccountkey

**Note:** Adzerk Data Shipping sometimes re-writes files using the same filename. If you want the Connector to only be allowed to create new files in Google Cloud, grant the `Storage Object Creator` role when generating your token. If you want the Connector to be able to overwrite files, you'll need to grant `Storage Object Admin`.

Once you've created the key, you'll need to save it locally and set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to the path of the JSON file. If there are spaces in the JSON token's filename, you'll need to ensure you properly escape them for the `make` tasks to succeed.

## Installation
Start by gathering the following configuration values to supply during deployment:
```bash
STACK_NAME # The chosen name for your CloudFormation Stack
LAMBDA_SOURCE_BUCKET # An S3 Bucket to use for uploading Lambda Source code
SOURCE_BUCKET # The name of your Adzerk Data Shipping Bucket
DESTINATION_BUCKET # The name of the GCP Storage Bucket
```

Once you have your configuration values, you are ready to start the deployment. If you're running for the first time, you should run the following command:
```bash
make create STACK_NAME=your-stack-name \
            LAMBDA_SOURCE_BUCKET=your-source-bucket \
            SOURCE_BUCKET=your-adzerk-data-bucket \
            DESTINATION_BUCKET=your-gcp-storage-bucket
```

If you've previously created the Stack and are just updating to the latest version, you can use the update command instead:
```
make update STACK_NAME=your-stack-name \
            LAMBDA_SOURCE_BUCKET=your-source-bucket \
            SOURCE_BUCKET=your-adzerk-data-bucket \
            DESTINATION_BUCKET=your-gcp-storage-bucket
```

## Architecture
![AWS Cloud to Google Cloud Platform Storage Diagram](https://raw.githubusercontent.com/adzerk/s3-to-google-cloud-storage-connector/master/doc/cloud_architecture.png?token=AAGBJEWDRTVFHC6NYULD2EC5VX4ZK)

The included CloudFormation template will set up several pieces of infrastructure.

1. A Lambda Function that will handle creating an S3 Event on an existing S3 Bucket.

2. A new S3 Event for your Adzerk Data Shipping Bucket.

3. A Lambda Function triggered by the new S3 Event that will ship the new file from S3 to GCP.

4. All necessary IAM permissions.