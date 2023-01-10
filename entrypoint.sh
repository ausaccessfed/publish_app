#!/bin/bash

# Update the image tag for project in the GitOps repository

set -e

projects=${1:-$PROJECTS}
tag=${2:-$IMAGE_TAG}
serial_number=${3:-$GITHUB_RUN_NUMBER}
# optional argument to specify which container in the pod (defaults to first)
environments=${4:-$ENVIRONMENTS}

if [ -z "$serial_number" ]; then
  echo "Usage: $0 projects tag serial_number environments"
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
    directory="manifests/${project}/overlays/${environment}"
    serial_number_filename="${directory}/container_${ECR_REPOSITORY}_serial_number.txt"
    # Ensure we don't accidentally overwrite newer images updates
    if [ -f "$serial_number_filename" ]; then
      last_serial_number=$(echo $(<"$serial_number_filename") | sed "s/SERIAL_NUMBER=//")
      if [ "$last_serial_number" -gt "$serial_number" ]; then
        echo "Attempted to update image with serial number $serial_number, but previous serial number was $last_serial_number. Image not updated."
        exit 1
      fi
    fi

    echo "SERIAL_NUMBER=$serial_number" > "$serial_number_filename"

    cd $directory
    kustomize edit set image $oci_repo_url:$tag
    cd -
  done
done

git config user.email "ci@aaf.edu.au"
git config user.name "AAF CI"
git pull
git add .
COMMIT_MESSAGE="Update ${projects} image tag ${ECR_REPOSITORY} to '$tag' for ${environments}"
git commit -m "$COMMIT_MESSAGE"
git push 

popd
rm -rf "$dir"
