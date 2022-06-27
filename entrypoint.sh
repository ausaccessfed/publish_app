#!/bin/bash

# Update the image tag for project in the GitOps repository

set -e

project=${1:-$ECR_REPOSITORY}
tag=${2:-$IMAGE_TAG}
serial_number=${3:-$GITHUB_RUN_NUMBER}
# optional argument to specify which container in the pod (defaults to first)
container_index=${4:-0}

if [ -z "$serial_number" ]; then
  echo "Usage: $0 project tag serial_number [container_index]"
  exit 1
fi

dir="$(mktemp -d)/manifests"

oci_repo_url=$(aws ssm get-parameter --name ${ECR_REPOSITORY}-repo-url --query "Parameter.Value" --output text)
git_user=$(aws ssm get-parameter --name git-ssl-username --query "Parameter.Value" --output text| tr -d '\n'| jq -sRr @uri)
git_password=$(aws ssm get-parameter --name git-ssl-password --query "Parameter.Value" --output text --with-decryption| tr -d '\n'| jq -sRr @uri)

git clone --depth 1 "https://${git_user}:${git_password}@git-codecommit.ap-southeast-2.amazonaws.com/v1/repos/manifests" "$dir"
pushd "$dir"

serial_number_filename="applications/${project}/overlays/current/container_${container_index}_serial_number.txt"

# Ensure we don't accidentally overwrite newer images updates
if [ -f "$serial_number_filename" ]; then
  last_serial_number=$(<"$serial_number_filename")
  if [ "$last_serial_number" -ge "$serial_number" ]; then
    echo "Attempted to update image with serial number $serial_number, but previous serial number was $last_serial_number. Image not updated."
    exit 1
  fi
fi

echo "$serial_number" > "$serial_number_filename"

cat <<-EOF > "applications/${project}/overlays/current/patch_image_${container_index}_tag.yaml"
- op: replace
  path: /spec/template/spec/containers/${container_index}/image
  value: "${oci_repo_url}:$tag"

EOF


git config user.email "ci@aaf.edu.au"
git config user.name "AAF CI"
git add .
git commit -m "Update ${project} image tag ${container_index} to '$tag'"
git push

popd
rm -rf "$dir"
