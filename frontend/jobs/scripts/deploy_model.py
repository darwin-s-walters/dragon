#!/usr/bin/env python

import os,argparse
from sagemaker import get_execution_role
import sagemaker as sage
from sagemaker.predictor import csv_serializer
import boto3
import datetime



parser=argparse.ArgumentParser()

parser.add_argument('--workspace', default=os.getcwd())
parser.add_argument('--buildid', default="")
parser.add_argument('--envname', default="dev")

args=parser.parse_args()
build_id = args.buildid
env_name = args.envname
endpoint_name = "{}-sm-endpoint".format(env_name)

# S3 prefix
sess = sage.Session()

role = get_execution_role()

ssm_client = boto3.client('ssm')
sagemaker_client = boto3.client('sagemaker')
endpoints = sagemaker_client.list_endpoints(NameContains=endpoint_name)
update_endpoints = len(endpoints['Endpoints'])

if env_name == 'dev':
    response = ssm_client.get_parameter(Name="/sagemaker/train_model/{}/training_job_name".format(build_id))
    training_job_name = response['Parameter']['Value']
    attached_estimator = sage.estimator.Estimator.attach(training_job_name)

    predictor = attached_estimator.deploy(1, 'ml.m4.xlarge',
                            serializer=csv_serializer,
                            update_endpoint=update_endpoints,
                            endpoint_name=endpoint_name)

    print ('Wait for endpoint in service')
    waiter = sagemaker_client.get_waiter('endpoint_in_service')
    waiter.wait(EndpointName=endpoint_name)
    print ('Endpoint is in service')
else:
    now=datetime.datetime.now()
    time_string = now.strftime('%Y-%m-%d-%H-%M-%S-%MS')

    lower_env_endpoint = ""
    if env_name == 'qa':
        lower_env_endpoint_name = "dev-sm-endpoint"
    elif env_name == 'prod':
        lower_env_endpoint_name = "qa-sm-endpoint"
    else:
      raise Exception('env_name must be dev, qa, or prod but {} was specified.'.format(env_name))

    lower_env_endpoint = sagemaker_client.describe_endpoint(
            EndpointName=lower_env_endpoint_name
        )

    lower_env_endpoint_config = sagemaker_client.describe_endpoint_config(
      EndpointConfigName=lower_env_endpoint['EndpointConfigName']
    )
    sess = sage.Session()

    model_name = lower_env_endpoint_config['ProductionVariants'][0]['ModelName']
    new_config_name = "{}-{}".format(endpoint_name, time_string)
    endpoint_config = sess.create_endpoint_config(name=new_config_name, model_name=model_name,
        initial_instance_count=1, instance_type="ml.m4.xlarge")

    if not update_endpoints:
        print ('creating endpoint')
        sess.create_endpoint(endpoint_name=endpoint_name, config_name=new_config_name, wait=True)
    else:
        print ('updating endpoint')
        sess.update_endpoint(endpoint_name=endpoint_name, endpoint_config_name=new_config_name)
        print ('Wait for endpoint in service')
        waiter = sagemaker_client.get_waiter('endpoint_in_service')
        waiter.wait(EndpointName=endpoint_name)
        print ('Endpoint is in service')
