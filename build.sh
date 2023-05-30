#!/bin/bash

SCRIPT_PATH="${BASH_SOURCE:-$0}"
ABS_SCRIPT_PATH="$(realpath "${SCRIPT_PATH}")"
SCRIPTDIR=$(dirname "${ABS_SCRIPT_PATH}")
cd "$SCRIPTDIR" || exit 1;

if [ ! -f .env ]; then
  echo "[ERROR] .env is not found.";
  exit 1;
fi

# shellcheck source=/dev/null
source .env

usage () {
	echo "$1"
	cat <<_EOT_

Usage:
	./build.sh

Description:
	Build a docker image of squid
_EOT_
}

if [ -z "${AWS_ACCOUNT_ID}" ]; then
  usage "[ERROR] AWS_ACCOUNT_ID is requied.";
  exit 1;
fi
if [ -z "${AWS_PROFILE}" ]; then
  usage "[ERROR] AWS_PROFILE is requied.";
  exit 1;
fi
if [ -z "${AWS_REGION}" ]; then
  usage "[ERROR] AWS_REGION is requied.";
  exit 1;
fi
if [ -z "${AWS_ECR_REPO_NAME}" ]; then
  usage "[ERROR] AWS_ECR_REPO_NAME is requied.";
  exit 1;
fi
if [ -z "${DOCKER_IMAGE_NAME}" ]; then
  usage "[ERROR] DOCKER_IMAGE_NAME is requied.";
  exit 1;
fi
if [ -z "${DOCKER_IMAGE_TAG}" ]; then
  usage "[ERROR] DOCKER_IMAGE_TAG is requied.";
  exit 1;
fi

# Step 1: Generate the tls certificate
./gen-cert.sh

# Step 2: Build the Docker image
docker build -t "$DOCKER_IMAGE_NAME" --platform linux/amd64 .

# Step 3: Tag the Docker image
docker tag "$DOCKER_IMAGE_NAME:latest" "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$AWS_ECR_REPO_NAME:$DOCKER_IMAGE_TAG"

# Step 4: Log in to ECR
aws ecr get-login-password --region "$AWS_REGION" --profile "$AWS_PROFILE" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Step 5: Check if the ECR repository exists
REPO_LIST=$(aws ecr describe-repositories --region "$AWS_REGION" --query 'repositories[*].repositoryName' --output text --profile "$AWS_PROFILE")

if [[ $REPO_LIST = *"$AWS_ECR_REPO_NAME"* ]]; then
  echo "Repository '$AWS_ECR_REPO_NAME' exists."
else
  echo "Repository '$AWS_ECR_REPO_NAME' does not exist. Creating it..."
  aws ecr create-repository \
    --repository-name "$AWS_ECR_REPO_NAME" \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability IMMUTABLE \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE"
fi

# Step 6: Push the Docker image to ECR
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$AWS_ECR_REPO_NAME:$DOCKER_IMAGE_TAG"

cd - || exit 1;
