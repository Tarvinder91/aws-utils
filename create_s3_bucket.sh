list="
bucketname-1
bucketname-2
bucketname-3"

$REGION=ap-southeast-2

for BUCKETNAME in $(echo $list)
do

  aws s3api create-bucket --bucket $BUCKETNAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION

  aws s3api put-bucket-encryption --bucket $BUCKETNAME --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
										
  aws s3api put-public-access-block --bucket $BUCKETNAME --public-access-block-configuration  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

done