status: cfn-status

docker-build:
	docker pull "steamcmd/steamcmd:alpine"
	docker pull teamspeak
	cd docker && docker compose build hambone

docker-shell:
	cd docker && docker compose run --rm hambone_shell

docker-run:
	cd docker && docker compose up hambone teamspeak

docker-run-fast:
	cd docker && docker compose up hambone_fast teamspeak

docker-push:
	aws ecr get-login-password \
	    | docker login --username AWS --password-stdin $(ECR_REGISTRY)
	docker build -t "hambone" docker
	docker tag "hambone" "$(ECR_REGISTRY)/hambone"
	docker push "$(ECR_REGISTRY)/hambone"
	docker logout

cfn-create:
	@. cloudformation/cloudformation.env &&				  \
	aws cloudformation create-stack					  \
	    --stack-name hambone					  \
	    --template-body file://cloudformation/cloudformation.yml	  \
	    --capabilities CAPABILITY_IAM				  \
	    --parameters						  \
	    ParameterKey=KeyName,ParameterValue=$$KEY_NAME		  \
	    ParameterKey=BucketName,ParameterValue=$$BUCKET_NAME	  \
	    ParameterKey=InstanceType,ParameterValue=$$INSTANCE_TYPE	  \
	    ParameterKey=SnapshotId,ParameterValue=$(CFN_SNAPSHOT_LATEST) \
	    ParameterKey=AMIID,ParameterValue=$$AMI_ID

cfn-update:
	@. cloudformation/cloudformation.env &&				\
	aws cloudformation update-stack					\
	    --stack-name hambone					\
	    --template-body file://cloudformation/cloudformation.yml	\
	    --capabilities CAPABILITY_IAM				\
	    --parameters						\
	    ParameterKey=KeyName,ParameterValue=$$KEY_NAME		\
	    ParameterKey=BucketName,ParameterValue=$$BUCKET_NAME	\
	    ParameterKey=InstanceType,ParameterValue=$$INSTANCE_TYPE	\
	    ParameterKey=AMIID,ParameterValue=$$AMI_ID

cfn-status:
	@aws cloudformation describe-stacks				\
	    --query "{stacks:Stacks[].{name:StackName,status:StackStatus}}"
	@aws ec2 describe-instances --query				\
	    "{								\
	        instances:Reservations[].Instances[].{			\
	            status:State.Name,id:InstanceId			\
	        }							\
	    }"
	@aws ec2 describe-volumes --query				\
	    "{volumes:Volumes[].{state:State,size:Size,id:VolumeId}}"
	@aws ec2 describe-snapshots					\
	    --owner-ids self						\
	    --query "{							\
	        snapshots:Snapshots[].{					\
	            size:VolumeSize,date:StartTime,id:SnapshotId	\
	        }							\
	    }"
	@aws s3api list-buckets						\
	    --query "{buckets:Buckets[].{created:CreationDate,name:Name}}"

cfn-events:
	@aws cloudformation describe-stack-events	\
	    --stack-name hambone			\
	    --query "StackEvents[].{			\
	        time:Timestamp,				\
	        status:ResourceStatus,			\
	        resource:LogicalResourceId		\
	    } | sort_by(@, &time)"			\
	    --output table

cfn-wait:
	@TIMEOUT=300;							\
	STEP=10;							\
	START_TIME=$$(date +%s);					\
	while true; do							\
	    printf "Checking stack status...";				\
	    STATUS=$$(							\
	        aws cloudformation list-stacks				\
	            --query "StackSummaries[?StackName=='hambone']	\
	                         | [0].StackStatus"			\
	            --output text					\
	    );								\
	    echo $$STATUS;						\
	    if [[ $$STATUS =~ COMPLETE ]]; then				\
	        exit 0;							\
	    fi;								\
	    CURRENT_TIME=$$(date +%s);					\
	    if (( CURRENT_TIME - START_TIME >= TIMEOUT )); then		\
	        echo "Timeout reached. Exiting.";			\
	        exit 1;							\
	    fi;								\
	    sleep $$STEP;						\
	done;

cfn-ssh:
	@. cloudformation/cloudformation.env &&		\
	DNS=$(CFN_DNS);					\
	if [ -n "$$DNS" ]; then				\
	    ssh -i "$$KEY_PATH" ec2-user@$$DNS;		\
	else						\
	    echo "EC2 instance not running." 2>&1;	\
	fi

cfn-stop:
	aws ec2 stop-instances --instance-ids $(CFN_EC2_ID)

cfn-start:
	aws ec2 start-instances --instance-ids $(CFN_EC2_ID)

snapshot-create:
	aws ec2 create-snapshot					\
	    --volume-id $(CFN_EBS_ID)				\
	    --description "Hambone data disk"			\
	    --tag-specifications "ResourceType=snapshot,Tags=[	\
	        {Key=Stack, Value=Hambone}			\
	    ]"

snapshot-list:
	@aws ec2 describe-snapshots				\
	    --owner-ids self					\
	    --filters "Name=tag:Stack,Values=Hambone"

snapshot-delete:
	@for snapshot in $(shell				\
	    aws ec2 describe-snapshots				\
	        --owner-ids self				\
	        --filters "Name=tag:Stack,Values=Hambone"	\
	        --query "Snapshots[].SnapshotId"		\
	        --output text					\
	); do							\
	    printf "Deleting %s..." $$snapshot;			\
	    aws ec2 delete-snapshot --snapshot-id $$snapshot;	\
	    echo "done.";					\
	done;

cfn-delete:
	aws cloudformation delete-stack --stack-name hambone

s3-docker-data:
	@. cloudformation/cloudformation.env				\
	&& TEMP_FILE=$$(mktemp -u).tar.gz				\
	&& cd docker							\
	&& tar -czf $$TEMP_FILE						\
	       userdata docker-compose-prod.yml docker-compose.env	\
	&& aws s3 cp $$TEMP_FILE s3://$$BUCKET_NAME/dockerdata.tar.gz	\
	&& rm $$TEMP_FILE

ECR_REGISTRY = $(CFN_ACCOUNT_ID).dkr.ecr.$(CFN_REGION).amazonaws.com

CFN_ACCOUNT_ID = $(shell						\
	aws sts get-caller-identity --query Account --output text	\
)

CFN_REGION = $(shell							\
	aws cloudformation describe-stacks				\
	    --stack-name hambone					\
	    --query							\
	    "Stacks[0].Outputs[?OutputKey=='Region'].OutputValue"	\
	    --output text						\
)

CFN_EC2_ID = $(shell							\
	aws cloudformation describe-stacks				\
	    --stack-name hambone					\
	    --query							\
	    "Stacks[0].Outputs[?OutputKey=='InstanceID'].OutputValue"	\
	    --output text						\
)

CFN_EBS_ID = $(shell					\
	aws ec2 describe-instances			\
	    --instance-ids i-055fe8b0797fdfb89		\
	    --query					\
	    "Reservations[0].Instances[0].		\
	        BlockDeviceMappings[1].Ebs.VolumeId"	\
	    --output text				\
)

CFN_SNAPSHOT_LATEST = $(shell						\
	aws ec2 describe-snapshots					\
	    --owner-ids self						\
	    --filters "Name=tag:Stack,Values=Hambone"			\
	    --query "sort_by(Snapshots, &StartTime)[-1].SnapshotId"	\
	    --output text						\
)

CFN_S3_ID = $(shell							\
	aws cloudformation describe-stacks				\
	    --stack-name hambone					\
	    --query							\
	    "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue"	\
	    --output text						\
)

CFN_DNS = $(shell							\
	aws ec2 describe-instances					\
	    --instance-ids $(CFN_EC2_ID)				\
	    --query "Reservations[0].Instances[0].PublicDnsName"	\
	    --output text						\
)

-include Makefile.local.mk
