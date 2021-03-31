#RUN COMMAND : sh script.sh mybucketname 

bucket=$1                   #bucket='yourbucketname'

if [ -z "$1" ]; then echo "Provide bucket name as ARG 1"; exit ; fi

#Get no. of obj in bucket
echo "No. of objects currently under this bucket:"
aws s3 ls --summarize --human-readable s3://$bucket --recursive > object-list-$bucket.txt
tail -3 object-list-$bucket.txt


# Get total no. of objects.
echo "Total no. of objects under this bucket including old version objects:"
aws s3api list-object-versions --bucket $bucket |jq '.Versions' > "all-objects-$bucket.json"
cat all-objects-$bucket.json | jq 'length'

#Get old version Objects
echo "Old version objects under this bucket:"
cat "all-objects-$bucket.json" |  jq '.[] | select(.IsLatest | not)' | jq -s > "old-objects-$bucket.json"
oldversions=$(cat "old-objects-$bucket.json")
echo $oldversions | jq 'length'


# MARKERS
echo "Delete markers:"
aws s3api list-object-versions --bucket $bucket   | jq '.DeleteMarkers' > "delete-markers-$bucket.json"

markers=$(cat "delete-markers-$bucket.json")
echo $markers | jq 'length'

