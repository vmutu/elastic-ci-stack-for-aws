<h1><img alt="Elastic CI Stack for AWS" src="https://cdn.rawgit.com/buildkite/elastic-ci-stack-for-aws/master/images/banner.png"></h1>

![Build status](https://badge.buildkite.com/d178ab942e2f606a83e79847704648437d82a9c5fdb434b7ae.svg?branch=master)

The Buildkite Elastic CI Stack for AWS gives you a private, autoscaling [Buildkite Agent](https://buildkite.com/docs/agent) cluster. Use it to parallelize legacy tests across hundreds of nodes, run tests and deployments for all your Linux and Windows-based services and apps, or run AWS ops tasks.

The stack is implemented using Cloud Formation, an AWS product for creating and managing a set of cloud resources (like autoscaling groups and EC2 virtual machines).

In addition to this README, our documentaion site includes some relevant info:

1. [A Tutorial](https://buildkite.com/docs/tutorials/elastic-ci-stack-aws)
2. [Detailed advice for many common configurations](https://buildkite.com/docs/agent/v3/aws)

Features:

- All major AWS regions
- Configurable instance size
- Configurable number of buildkite agents per instance
- Configurable spot instance bid price
- Configurable auto-scaling based on build activity
- Docker and Docker Compose support
- Per-pipeline S3 secret storage (with SSE encryption support)
- Docker Registry push/pull support
- CloudWatch logs for system and buildkite agent events
- CloudWatch metrics from the Buildkite API
- Support for stable, beta or edge Buildkite Agent releases
- Create as many instances of the stack as you need
- Rolling updates to stack instances to reduce interruption

## Contents

<!-- toc -->

- [Getting Started](#getting-started)
- [Build Secrets](#build-secrets)
- [What’s On Each Machine?](#whats-on-each-machine)
- [What Type of Builds Does This Support?](#what-type-of-builds-does-this-support)
- [Versions](#versions)
- [Updating Your Stack](#updating-your-stack)
- [Reading Instance and Agent Logs](#reading-instance-and-agent-logs)
- [Security](#security)
- [Development](#development)
- [Questions and Support](#questions-and-support)
- [Licence](#licence)

<!-- tocstop -->

## Getting Started

See the [Elastic CI Stack for AWS guide](https://buildkite.com/docs/guides/elastic-ci-stack-aws) for a step-by-step guide, or jump straight in:

[![Launch AWS Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=buildkite&templateURL=https://s3.amazonaws.com/buildkite-aws-stack/latest/aws-stack.yml)

Current release is ![](https://img.shields.io/github/release/buildkite/elastic-ci-stack-for-aws.svg). See [Releases](https://github.com/buildkite/elastic-ci-stack-for-aws/releases) for older releases, or [Versions](#versions) for development version

> Although the stack will create it's own VPC by default, we highly recommend following best practice by setting up a separate development AWS account and using role switching and consolidated billing—see the [Delegate Access Across AWS Accounts tutorial](http://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html) for more information.

If you'd like to use the [AWS CLI](https://aws.amazon.com/cli/), download [`config.json.example`](config.json.example), rename it to `config.json`, and then run the below command:

```bash
aws cloudformation create-stack \
  --output text \
  --stack-name buildkite \
  --template-url "https://s3.amazonaws.com/buildkite-aws-stack/latest/aws-stack.yml" \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameters "$(cat config.json)"
```

## Build Secrets

The stack will have created an S3 bucket for you (or used the one you provided as the `SecretsBucket` parameter). This will be where the agent will fetch your SSH private keys for source control, and environment hooks to provide other secrets to your builds.

The following s3 objects are downloaded and processed:

* `/env` - An [agent environment hook](https://buildkite.com/docs/agent/hooks)
* `/private_ssh_key` - A private key that is added to ssh-agent for your builds
* `/git-credentials` - A [git-credentials](https://git-scm.com/docs/git-credential-store#_storage_format) file for git over https
* `/{pipeline-slug}/env` - An [agent environment hook](https://buildkite.com/docs/agent/hooks), specific to a pipeline
* `/{pipeline-slug}/private_ssh_key` - A private key that is added to ssh-agent for your builds, specific to the pipeline
* `/{pipeline-slug}/git-credentials` - A [git-credentials](https://git-scm.com/docs/git-credential-store#_storage_format) file for git over https, specific to a pipeline

These files are encrypted using [Amazon's KMS Service](https://aws.amazon.com/kms/). See the [Security](#security) section for more details.

Here's an example that shows how to generate a private SSH key, and upload it with KMS encryption to an S3 bucket:

```bash
# generate a deploy key for your project
ssh-keygen -t rsa -b 4096 -f id_rsa_buildkite
pbcopy < id_rsa_buildkite.pub # paste this into your github deploy key

aws s3 cp --acl private --sse aws:kms id_rsa_buildkite "s3://${SecretsBucket}/private_ssh_key"
```

If you want to set secrets that your build can access, create a file that sets environment variables and upload it:

```bash
echo "export MY_ENV_VAR=something secret" > myenv
aws s3 cp --acl private --sse aws:kms myenv "s3://${SecretsBucket}/env"
rm myenv
```

**Note: Currently only using the default KMS key for s3 can be used, follow [#235](https://github.com/buildkite/elastic-ci-stack-for-aws/issues/235) for progress on using specific KMS keys**

## What’s On Each Machine?

* [Amazon Linux 2 LTS](https://aws.amazon.com/amazon-linux-2/)
* [Buildkite Agent v3.25.0](https://buildkite.com/docs/agent)
* [Docker](https://www.docker.com) - 19.03.13 (Linux) and 19.03.12 (Windows)
* [Docker Compose](https://docs.docker.com/compose/) - 1.27.4 (Linux) and 1.27.2 (Windows)
* [aws-cli](https://aws.amazon.com/cli/) - useful for performing any ops-related tasks
* [jq](https://stedolan.github.io/jq/) - useful for manipulating JSON responses from cli tools such as aws-cli or the Buildkite API

## What Type of Builds Does This Support?

This stack is designed to run your builds in a share-nothing pattern similar to the [12 factor application principals](http://12factor.net):

* Each project should encapsulate it's dependencies via Docker and Docker Compose
* Build pipeline steps should assume no state on the machine (and instead rely on [build meta-data](https://buildkite.com/docs/guides/build-meta-data), [build artifacts](https://buildkite.com/docs/guides/artifacts) or S3)
* Secrets are configured via environment variables exposed using the S3 secrets bucket

By following these simple conventions you get a scaleable, repeatable and source-controlled CI environment that any team within your organization can use.

## Versions

Releases are published to the following stable URLs, suitable for passing to CloudFormation:

* The latest stable release: https://s3.amazonaws.com/buildkite-aws-stack/aws-stack.yml
* A URL for each release: https://s3.amazonaws.com/buildkite-aws-stack/${VERSION}/aws-stack.yml
  * Versioned URLs are available on the [releases page](https://github.com/buildkite/elastic-ci-stack-for-aws/releases)
* The latest master branch build: https://s3.amazonaws.com/buildkite-aws-stack/master/aws-stack.yml
* Master branch builds for each commit: https://s3.amazonaws.com/buildkite-aws-stack/master/${COMMIT}.aws-stack.yml
* The latest build for unmerged branches: https://s3.amazonaws.com/buildkite-aws-stack/${BRANCH}/aws-stack.yml

## Updating Your Stack

To update your stack to the latest version use CloudFormation’s stack update tools with one of the urls in the [Versions](#versions) section.

Prior to updating, it's a good idea to set the desired instance size on the AutoscalingGroup to 0 manually.

## Reading Instance and Agent Logs

Each instance streams both system messages and Buildkite Agent logs to CloudWatch Logs under several log groups:

* `/var/log/buildkite-agent.log` -> `/buildkite/buildkite-agent`
* `/var/log/cfn-init.log` -> `/buildkite/cfn-init`
* `/var/log/cloud-init.log` -> `/buildkite/cloud-init`
* `/var/log/cloud-init-output.log` -> `/buildkite/cloud-init/output`
* `/var/log/docker` - `/buildkite/docker-daemon`
* `/var/log/elastic-stack.log` - `/buildkite/elastic-stack`
* `/var/log/messages` -> `/buildkite/system`

Within each stream the logs are grouped by instance id.

To debug an agent first find the instance id from the agent in Buildkite, head to your [CloudWatch Logs Dashboard](https://console.aws.amazon.com/cloudwatch/home?#logs:), choose the relevant log group, and then search for the instance id in the list of log streams.

## Security

This repository hasn't been reviewed by security researchers so exercise caution and careful thought with what credentials you make available to your builds.

Anyone with commit access to your codebase (including third-party pull-requests if you've enabled them in Buildkite) will have access to your secrets bucket files.

Also keep in mind the EC2 HTTP metadata server is available from within builds, which means builds act with the same IAM permissions as the instance.

## Development

To get started with customizing your own stack, or contributing fixes and features:

```bash
# Checkout all submodules
git submodule update --init --recursive

# Build all AMIs and render a cloud formation template - this requires AWS credentials (in the ENV)
# to build an AMI with packer
make build

# To create a new stack on AWS using the local template
make create-stack

# You can use any of the AWS* environment variables that the aws-cli supports
AWS_PROFILE="some-profile" make create-stack

# You can also use aws-vault or similar
aws-vault exec some-profile -- make create-stack
```

If you need to build your own AMI (because you've changed something in the `packer` directory), run:

```bash
make packer
```

## Questions and Support

Feel free to drop an email to support@buildkite.com with questions. It helps us if you can provide the following details:

```
# List your stack parameters
aws cloudformation describe-stacks --stack-name MY_STACK_NAME \
  --query 'Stacks[].Parameters[].[ParameterKey,ParameterValue]' --output table
```

Provide us with logs from Cloudwatch Logs, as described above.

Alternately, drop by `#aws-stack` and `#aws` channels in [Buildkite Community Slack](https://chat.buildkite.com/) and ask your question!

## Licence

See [Licence.md](Licence.md) (MIT)
