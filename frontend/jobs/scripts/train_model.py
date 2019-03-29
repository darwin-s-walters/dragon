#!/usr/bin/env python

import os,argparse
from sagemaker import get_execution_role
import sagemaker as sage
from sagemaker.predictor import csv_serializer
import boto3
import json


parser=argparse.ArgumentParser()

parser.add_argument('--image', required=True, help='name of the docker image')
parser.add_argument('--version', default="latest", help='version/tag to pull from ecr')
parser.add_argument('--workspace', default=os.getcwd())
parser.add_argument('--modeluri', default="")
parser.add_argument('--buildid', default="")

args=parser.parse_args()

# S3 prefix
sess = sage.Session()

role = get_execution_role()

## parameterize this
training_input = "s3://{}/training/data".format(sess.default_bucket())

## need to pass in image + tag name
account = sess.boto_session.client('sts').get_caller_identity()['Account']
region = sess.boto_session.region_name
image = '{}.dkr.ecr.{}.amazonaws.com/{}:{}'.format(account, region, args.image, args.version)
param_path = '{}/input/config/hyperparameters.json'.format(args.workspace)
model_uri = args.modeluri
build_id = args.buildid


## hyperparameter

# LogisticRegression(C=6, class_weight=None, dual=False, fit_intercept=True,
#           intercept_scaling=1, max_iter=100, multi_class='ovr', n_jobs=1,
#           penalty='l1', random_state=None, solver='liblinear', tol=0.0001,
#           verbose=0, warm_start=False)

#hyperparameters = dict(batch_size=32, data_augmentation=True, learning_rate=.0001,
#                       width_shift_range=.1, height_shift_range=.1, epochs=1)



with open(param_path, 'r') as tc:
    hyperparameters = json.load(tc)

# hyperparameters = dict(C=6, class_weight=None, dual=False, fit_intercept=True,
#           intercept_scaling=1, max_iter=100, multi_class='ovr', n_jobs=1,
#           penalty='l1', random_state=None, solver='liblinear', tol=0.0001,
#           verbose=0, warm_start=False)

tags = [{"Key": "BuildId", "Value": build_id} ]

tree = sage.estimator.Estimator(image,
                       role, 1, 'ml.c4.2xlarge',
                       output_path="s3://{}/training/".format(sess.default_bucket()),
                       sagemaker_session=sess, hyperparameters=hyperparameters,
                       model_uri=model_uri, tags=tags)
tree.fit(training_input)
##i need to tag what was the prev model
##how do i know it's retraining vs fresh training
##training_job_analytics

print(tree.latest_training_job.name)
print(tree.model_data)

ssm_client = boto3.client('ssm')

response = ssm_client.put_parameter(
    Name="/sagemaker/train_model/{}/training_job_name".format(build_id),
    Description='training job name for the jenkins build id',
    Value=tree.latest_training_job.name,
    Type='String')
