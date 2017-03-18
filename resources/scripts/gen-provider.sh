#!/bin/bash -e
#
# Init variables and sanity checks

# Remove quotes
TF_REMOTE_STATE_BUCKET=${TF_REMOTE_STATE_BUCKET%%\"}
TF_REMOTE_STATE_BUCKET=${TF_REMOTE_STATE_BUCKET##\"}
TF_REMOTE_STATE_PATH=${TF_REMOTE_STATE_PATH%%\"}
TF_REMOTE_STATE_PATH=${TF_REMOTE_STATE_PATH##\"}
TF_VERSION=${TF_VERSION%%\"}
TF_VERSION=${TF_VERSION##\"}
TF_REMOTE_STATE_REGION=${TF_REMOTE_STATE_REGION%%\"}
TF_REMOTE_STATE_REGION=${TF_REMOTE_STATE_REGION##\"}
AWS_PROFILE=${AWS_PROFILE%%\"}
AWS_PROFILE=${AWS_PROFILE##\"}
AWS_REGION=${AWS_REGION%%\"}
AWS_REGION=${AWS_REGION##\"}
TF_MAX_RETRIES=${TF_MAX_RETRIES%%\"}
TF_MAX_RETRIES=${TF_MAX_RETRIES##\"}

#TF_VAR_aws_region=$($DIR/read_cfg.sh $HOME/.aws/config "profile $AWS_PROFILE" region)
aws_user=$(aws --profile $AWS_PROFILE iam get-user)
AWS_USER_NAME=$(echo $aws_user | jq --raw-output '.User.UserName')
AWS_ACCOUNT=$(echo $aws_user | jq ".User.Arn" | grep -Eo '[[:digit:]]{12}')
ALLOW_SSH_CIDR="$(curl -s http://ipinfo.io/ip)/32"

cat <<EOF
# Generated by scripts/gen-provider.sh
terraform {
  required_version = "${TF_VERSION}"
  backend "s3" {
    bucket = "${TF_REMOTE_STATE_BUCKET}"
    key    = "${TF_REMOTE_STATE_PATH}"
    region = "${TF_REMOTE_STATE_REGION}"
    encrypt = "true"
  }
}

provider "aws" {
  profile = "$AWS_PROFILE"
  max_retries = "$TF_MAX_RETRIES"
  region = "$AWS_REGION"
EOF
if [ ! -z $ALLOWED_ACCOUNT_IDS ]; then
    echo  \ \ allowed_account_ids = [ "$ALLOWED_ACCOUNT_IDS" ]
elif [[ ! -z $FORBIDDEN_ACCOUNT_IDS ]]; then
    echo  \ \ forbidden_account_ids = [ "$FORBIDDEN_ACCOUNT_IDS" ]
fi
cat <<EOF
}
variable "aws_account" {
    default = {
        id = "$AWS_ACCOUNT"
        default_region = "$AWS_REGION"
        profile = "$AWS_PROFILE"
    }
}
variable "iamuser" {
    default = "${AWS_USER_NAME}"
}
EOF
