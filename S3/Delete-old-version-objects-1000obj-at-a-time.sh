# This script should be used to delete the old version of the objects except the latest one under a S3 path prefix
# This script will also delete the Delete-Markers of objects under the prefix.
# RUN COMMAND : sh script.sh <bucketname> <prefix>


bucket=$1                   
prefix=$2                    

if [ -z "$1" ]; then echo "Provide bucket name as ARG 1"; exit ; fi
if [ -z "$2" ]; then echo "Provide prefix name as ARG 2"; exit ; fi

mkdir "$prefix" -p 2>/dev/null
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
cat "all-objects-$bucket.json" |  jq '.[] | select(.IsLatest | not)' | jq -s '.' > "old-objects-$bucket.json"

no_of_obj=$(cat old-objects-$bucket.json | jq 'length')
echo $no_of_obj

i=0
while [ $i -lt $no_of_obj ]
do
    next=$((i+999))
    oldversions=$(cat "old-objects-$bucket.json" |  jq '.[] | {Key,VersionId}' | jq -s '.' | jq .[$i:$next])
        cat << EOF > deleted-files-start-index-$i.json
        {"Objects":$oldversions, "Quiet":true }
EOF
        echo "Deleting records from $i - $next"
        aws s3api delete-objects --bucket "$bucket" --delete file://deleted-files-start-index-$i.json

        let i=i+1000
done

#DELETE MARKERS
aws s3api list-object-versions --bucket $bucket   --prefix $prefix  | jq '.DeleteMarkers' > "delete-markers-$bucket.json"

no_of_markers=$(cat "delete-markers-$bucket.json"| jq 'length')
echo "Delete markers:"
echo $no_of_markers

i=0
while [ $i -lt $no_of_markers ]
do
    next=$((i+999))
    markers=$(cat "delete-markers-$bucket.json" |  jq '.[] | {Key,VersionId}' | jq -s '.' | jq .[$i:$next])
        cat << EOF > deleted-markers-start-index-$i.json
        {"Objects":$markers, "Quiet":true }
EOF
        echo "Deleting markers from $i - $next"
        aws s3api delete-objects --bucket "$bucket" --delete file://deleted-markers-start-index-$i.json

        let i=i+1000
done


echo "Get size of a prefix again"
aws s3 ls --summarize --human-readable s3://$bucket/$prefix --recursive > object-list-$bucket-AFTER-DELETION.txt
tail -3 object-list-$bucket-AFTER-DELETION.txt


	
		