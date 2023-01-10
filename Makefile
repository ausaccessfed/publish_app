-include .env
all:
	make login
	make build
	make push
build:
	docker build . --platform=amd64 -t ${DOCKER_ECR}publish_app
	docker tag ${DOCKER_ECR}publish_app ${DOCKER_ECR}publish_app:latest
push:
	docker push ${DOCKER_ECR}publish_app:latest
login:
	@if [ "${DOCKER_ECR}" != "" ]; then \
		aws-vault exec shared_services -- aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin ${DOCKER_ECR}; \
	fi

