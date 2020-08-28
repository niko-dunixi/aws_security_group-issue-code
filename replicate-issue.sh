#!/usr/bin/env bash
set -ex

if ! hash terraform &> /dev/null; then
  tf_version="0.13.1"
  function terraform() {
    aws_env_file="$(mktemp)"
    aws-okta env "${AWS_PROFILE}" | awk '{print $2}' > "${aws_env_file}"
    docker run -it \
      --env-file "${aws_env_file}" \
      --env AWS_REGION="${AWS_REGION}" \
      --env TF_LOG_PATH="/hostdir/issue-plan.log" \
      --env TF_LOG="TRACE" \
      -v "$(pwd):/hostdir" \
      -w "${workdir:-/hostdir}" \
      -u $(id -u ${USER}):$(id -g ${USER}) \
      "hashicorp/terraform:${tf_version}" ${@}
  }
fi

function cleanup() {
  terraform destroy -auto-approve
  rm -f terraform.{tfstate,tfstate.backup}
}

[ ! -f issue-plan.log ] || rm -f issue-plan.log
terraform init
terraform apply -auto-approve
trap cleanup EXIT
terraform plan -out issue-plan.bin
terraform show -json issue-plan.bin | jq > issue-plan.json
