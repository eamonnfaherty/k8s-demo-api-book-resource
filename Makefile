.PHONEY: test build validate-pipeline create-pipeline update-pipeline delete-pipeline build clean
include default.properties

TARGET_BUCKET="$(shell aws ssm get-parameter --name $(repos.helm.param_name) --query 'Parameter.Value' --output text)"

test:
	mkdir -p reports
	docker run --rm -v $$PWD/src:/code eeacms/pep8 | sed 's/\/code\//src\//'g > reports/pep8.out

clean:
	rm -rf build

build:
	docker build . -t $${ECR_REPO}:$${CODEBUILD_RESOLVED_SOURCE_VERSION}
	@$$(aws ecr get-login --no-include-email) && docker push $${ECR_REPO}:$${CODEBUILD_RESOLVED_SOURCE_VERSION}

package-helm-chart:
	mkdir build
	aws s3 cp s3://$(TARGET_BUCKET)/chart.tar build/chart.tar
	cd build && tar xvf chart.tar
	echo "Name: $(pipeline.name)" >> build/chart/Chart.yaml
	echo "Description: $(pipeline.description)" >> build/chart/Chart.yaml
	echo "Version: $(version.major).$(version.minor).$(version.patch)+$${CODEBUILD_RESOLVED_SOURCE_VERSION}" >> build/chart/Chart.yaml
	echo "appVersion: $(version.major).$(version.minor).$(version.patch)+$${CODEBUILD_RESOLVED_SOURCE_VERSION}" >> build/chart/Chart.yaml
	mv build/chart build/$(pipeline.name)
	helm template build/$(pipeline.name) \
		--set name=$(pipeline.name) \
		--set Name=$(pipeline.name) \
		--set image.repository=foo \
		--set image.tag=bar \
		--set service.type=ClusterIP \
		--output-dir build
	cd build && helm package $(pipeline.name) \
		--app-version $${CODEBUILD_RESOLVED_SOURCE_VERSION} \
		--version $(version.major).$(version.minor).$(version.patch)+$${CODEBUILD_RESOLVED_SOURCE_VERSION}

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


