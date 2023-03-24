#!/bin/bash

# Update the image tag for project in the GitOps repository

set -e

projects=${1:-$PROJECTS}
tag=${2:-$IMAGE_TAG}
environments=${3:-$ENVIRONMENTS}

if [ -z "$environments" ]; then
  echo "Usage: $0 projects tag environments"
  exit 1
fi

dir="$(mktemp -d)/terraform"

oci_repo_url=$(aws ssm get-parameter --name ${ECR_REPOSITORY}-repo-url --query "Parameter.Value" --output text)
git_user=$(aws ssm get-parameter --name argocd-git-ssl-username --query "Parameter.Value" --output text| tr -d '\n'| jq -sRr @uri)
git_password=$(aws ssm get-parameter --name argocd-git-ssl-password --query "Parameter.Value" --output text --with-decryption| tr -d '\n'| jq -sRr @uri)

git clone --depth 1 "https://${git_user}:${git_password}@github.com/ausaccessfed/aaf-terraform.git" "$dir"
pushd "$dir"
for project in $(echo $projects | tr "," "\n");
do
  for environment in $(echo $environments | tr "," "\n");
  do
    DIRECTORY="manifests/${project}/overlays/${environment}"
    if [ -d "$DIRECTORY" ]; then
      if [ "$environment" == "jisc" ]; then
        oci_repo_url=$(aws ssm get-parameter --name ${ECR_REPOSITORY}-eu-west-2-repo-url --query "Parameter.Value" --output text)
      else
        oci_repo_url=$(aws ssm get-parameter --name ${ECR_REPOSITORY}-repo-url --query "Parameter.Value" --output text)
      fi
      cd "$DIRECTORY"
      kustomize edit set image $oci_repo_url:$tag
      cd -
    fi
  done
done

git config user.email "ci@aaf.edu.au"
git config user.name "AAF CI"
git pull
git add .
COMMIT_MESSAGE="Update ${projects} image tag ${ECR_REPOSITORY} to '$tag' for ${environments}"
git commit -m "$COMMIT_MESSAGE" || echo "nothing to commit"
git push 

popd
rm -rf "$dir"
