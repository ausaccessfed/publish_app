# Publish App GitHub Action

This action updates the GitOps manifests repository to reflect the current version
of the specified application. Depending on the configuration of ArgoCD, this may trigger the application
to be redeployed.


## Example usage

See [usage in Validator-Service pipeline].

## Managing Releases of the GitHub Action

We use tags for release management as described in the [GitHub Actions Manual].

[usage in Validator-Service pipeline]: https://github.com/ausaccessfed/validator-service/blob/cfacbe3063bbda00373ad3aced0898ce594ed43d/.github/workflows/deploy.yml#L108
[GitHub Actions Manual]: https://docs.github.com/en/actions/creating-actions/about-custom-actions#using-tags-for-release-management

