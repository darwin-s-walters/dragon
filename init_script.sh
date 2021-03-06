#!/bin/bash -ex

export AWS_DEFAULT_REGION='us-east-1'
export env_name='dragon'
export cfn_template_bucket_stack_name='cfn-template-bucket'
export ssh_key_pair_name='dragon-ssh-key'
export jenkins_user='jenkins'
export jenkins_instance_type="t2.large"

#aws secretsmanager create-secret --name JenkinsPassword --description "Jenkins admin password" --secret-string "add your password"
#this requires aws cli v1.16.11 - run pip install awscli==1.16.11

echo 'Generating EC2 ssh key pair'
export key_pair=$(aws ec2 describe-key-pairs --filters Name=key-name,Values=${ssh_key_pair_name} | jq .KeyPairs[0])

if [[ "$key_pair" == "null" ]]; then
  aws ec2 create-key-pair --key-name ${ssh_key_pair_name} | jq -r .KeyMaterial > ${ssh_key_pair_name}.pem
  aws secretsmanager create-secret --name ${ssh_key_pair_name} --description "${ssh_key_pair_name} key pair private key" --secret-string file://${ssh_key_pair_name}.pem
else
  echo "SSH key pair, ${ssh_key_pair_name}, already exists"
fi

echo "Validate cfn templates"
#./tests/validate-templates.sh

echo 'Creating s3 bucket for cfn templates'
aws cloudformation deploy --template-file ./infrastructure/cfn-template-bucket.yml \
  --stack-name ${cfn_template_bucket_stack_name}  --no-fail-on-empty-changeset

export bucket_name=$(aws cloudformation describe-stacks --stack-name cfn-template-bucket | jq .Stacks[0].Outputs[0].OutputValue -r)

#aws s3api wait bucket-exists --bucket ${bucket_name}

echo 'Uploading cfn templates to s3 bucket'
aws s3 sync ./infrastructure s3://${bucket_name}/${env_name}

echo 'Creating infrastructure'
aws cloudformation deploy --template-file ./infrastructure/master.yml \
  --stack-name ${env_name}  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      VpcTemplateUrl=$(aws s3 presign s3://${bucket_name}/${env_name}/vpc.yml) \
      SgTemplateUrl=$(aws s3 presign s3://${bucket_name}/${env_name}/security-groups.yml) \
      LbTemplateUrl=$(aws s3 presign s3://${bucket_name}/${env_name}/load-balancers.yml) \
      EcsTemplateUrl=$(aws s3 presign s3://${bucket_name}/${env_name}/ecs-cluster.yml) \
      KeyName="${ssh_key_pair_name}" \
      LifecycleHookTemplateUrl=$(aws s3 presign s3://${bucket_name}/${env_name}/lifecyclehook.yml)

export vpc=$(aws cloudformation describe-stacks --stack-name ${env_name} | jq '.Stacks[0].Outputs[] | select(.OutputKey == "VPC") | .OutputValue' -r)
export public_subnet_1=$(aws cloudformation describe-stacks --stack-name ${env_name} | jq '.Stacks[0].Outputs[] | select(.OutputKey == "PublicSubnet1") | .OutputValue' -r)
export private_subnet_1=$(aws cloudformation describe-stacks --stack-name ${env_name} | jq '.Stacks[0].Outputs[] | select(.OutputKey == "PrivateSubnet1") | .OutputValue' -r)
export public_subnets=$(aws cloudformation describe-stacks --stack-name ${env_name} | jq '.Stacks[0].Outputs[] | select(.OutputKey == "PublicSubnets") | .OutputValue' -r)

echo 'Deploying Jenkins'
aws cloudformation deploy --template-file ./jenkins/jenkins.yml \
  --stack-name ${env_name}-jenkins  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      KeyName="${ssh_key_pair_name}" \
      VpcId="${vpc}"\
      LBSubnets="${public_subnets}" \
      InstanceSubnet="${public_subnet_1}" \
      InstanceType="${jenkins_instance_type}" \
      JenkinsUser="${jenkins_user}" \
      JenkinsPassword="$(aws secretsmanager get-secret-value --secret-id JenkinsPassword | jq .SecretString -r)"
