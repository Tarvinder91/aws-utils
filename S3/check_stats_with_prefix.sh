#RUN COMMAND : sh script.sh mybucket myprefix

bucket=$1                   #bucket='jobs-test'
prefix=$2                   #prefix='test'

if [ -z "$1" ]; then echo "Provide bucket name as ARG 1"; exit ; fi
if [ -z "$2" ]; then echo "Provide prefix name as ARG 2"; exit ; fi

mkdir "$prefix" -p 
cd $prefix
# Get size of a prefix
echo "No. of objects currently under this prefix(current version):"
aws s3 ls --summarize --human-readable s3://$bucket/$prefix --recursive > object-list-$bucket.txt
tail -3 object-list-$bucket.txt


# Get total no. of objects.
echo "Total no. of objects under this prefix including old version objects:"
aws s3api list-object-versions --prefix $prefix --bucket $bucket |jq '.Versions' > "all-objects-$bucket.json"
cat all-objects-$bucket.json | jq 'length'

#Get old version Objects
echo "Old version objects under this prefix:"
cat "all-objects-$bucket.json" |  jq '.[] | select(.IsLatest | not)' | jq -s > "old-objects-$bucket.json"
oldversions=$(cat "old-objects-$bucket.json")
echo $oldversions | jq 'length'


# MARKERS

aws s3api list-object-versions --bucket $bucket   --prefix $prefix  | jq '.DeleteMarkers' > "delete-markers-$bucket.json"

markers=$(cat "delete-markers-$bucket.json")
echo "Delete markers:"
echo $markers | jq 'length'








