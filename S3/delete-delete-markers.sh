#Run the script as :
# sh ./delete-delete-markers.sh <bucketname> <prefix>

bucket=$1  	            #bucket='jobs-bucket'
prefix=$2				#prefix='test'

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


#DELETE MARKERS delete one at a time.

#aws s3api list-object-versions --bucket $bucket   --prefix $prefix  | jq '.DeleteMarkers' > "delete-markers-$bucket.json"

#markers=$(cat "delete-markers-$bucket.json")
#echo "Delete markers:"
#echo $markers | jq 'length'

#echo "removing delete markers"
#for marker in $(echo "${markers}" | jq -r '.[] | @base64'); do 
#    marker=$(echo ${marker} | base64 --decode)
#
#    key=`echo $marker | jq -r .Key`
#    versionId=`echo $marker | jq -r .VersionId `
#    cmd="aws s3api delete-object --bucket $bucket --key $key --version-id $versionId"
#    echo $cmd
#    $cmd
#done
#------------------

#DELETE markers delete in Bulk operation

echo "Delete markers:"
aws s3api list-object-versions --bucket $bucket   --prefix $prefix  | jq '.DeleteMarkers' > "delete-markers-$bucket.json"

no_of_markers=$(cat "delete-markers-$bucket.json"| jq 'length')
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






