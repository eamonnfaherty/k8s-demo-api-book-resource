.PHONEY: test build validate-pipeline create-pipeline update-pipeline delete-pipeline
include default.properties

ECR_REGISTRY="$(shell aws ssm get-parameter --name DockerRegistryURI --query 'Parameter.Value' --output text)"

test:
	mkdir -p reports
	docker run --rm -v $$PWD/src:/code eeacms/pep8 | sed 's/\/code\//src\//'g > reports/pep8.out

build:
	docker build . -t $(ECR_REGISTRY):$(docker.image_name)
	$$(aws ecr get-login --no-include-email) && docker push $(ECR_REGISTRY):$(docker.image_name)

validate:
	aws cloudformation validate-template --template-body file://$(pipeline.template)

create-pipeline:
	aws cloudformation create-stack \
		--stack-name $(pipeline.stack-name) \
		--template-body file://$(pipeline.template) \
		--parameters \
			ParameterKey=Owner,ParameterValue=$(params.owner) \
			ParameterKey=Repo,ParameterValue=$(params.repo) \
			ParameterKey=Branch,ParameterValue=$(params.branch) \
			ParameterKey=ProjectOAuthTokenSecretName,ParameterValue=$(params.project-oauth-token-param-name) \
			ParameterKey=WebHookOAuthTokenSecretName,ParameterValue=$(params.webhook-oauth-token-param-name) \
			ParameterKey=PipelineName,ParameterValue=$(pipeline.name) \
		--capabilities CAPABILITY_IAM
	aws cloudformation wait stack-create-complete --stack-name $(pipeline.stack-name)

update-pipeline:
	aws cloudformation update-stack \
		--stack-name $(pipeline.stack-name) \
		--template-body file://$(pipeline.template) \
		--parameters \
			ParameterKey=Owner,ParameterValue=$(params.owner) \
			ParameterKey=Repo,ParameterValue=$(params.repo) \
			ParameterKey=Branch,ParameterValue=$(params.branch) \
			ParameterKey=ProjectOAuthTokenSecretName,ParameterValue=$(params.project-oauth-token-param-name) \
			ParameterKey=WebHookOAuthTokenSecretName,ParameterValue=$(params.webhook-oauth-token-param-name) \
			ParameterKey=PipelineName,ParameterValue=$(pipeline.name) \
		--capabilities CAPABILITY_IAM
	aws cloudformation wait stack-update-complete --stack-name $(pipeline.stack-name)

delete-pipeline:
	aws cloudformation delete-stack \
		--stack-name $(pipeline.stack-name)
	aws cloudformation wait stack-delete-complete --stack-name $(pipeline.stack-name)


