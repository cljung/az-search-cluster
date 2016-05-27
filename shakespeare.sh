#!/bin/bash

ipaddr=$1
echo $(date +"%F %T%z") "Starting shakespeare.sh"

# download Shakespeare quotes
if [ -e "./shakespeare.json" ]
then
  echo "json file exists"
else
  wget https://www.elastic.co/guide/en/kibana/3.0/snippets/shakespeare.json
fi

echo $(date +"%F %T%z") "Waiting for Load Balancer $ipaddr to be ready"

# sleep 5 minutes and give ElasticSearch cluster time to initialize 
sleep 300
# wait until ES LB responds with http 200 OK
#resp="000"
resp=$(curl --write-out %{http_code} --silent --output /dev/null $ipaddr:9200)
while [ $resp -ne "200" ]
do
    echo $(date +"%F %T%z") "HTTP_Code="$resp
    sleep 60
    resp=$(curl --write-out %{http_code} --silent --output /dev/null $ipaddr:9200)
done 

echo $(date +"%F %T%z") "importing schema"

# create schema
curl -XPUT http://$ipaddr:9200/shakespeare -d '
{
 "mappings" : {
  "_default_" : {
   "properties" : {
    "speaker" : {"type": "string", "index" : "not_analyzed" },
    "play_name" : {"type": "string", "index" : "not_analyzed" },
    "line_id" : { "type" : "integer" },
    "speech_number" : { "type" : "integer" }
   }
  }
 }
}
';

echo $(date +"%F %T%z") "Importing data"

# import data
curl -XPUT http://$ipaddr:9200/_bulk --output /dev/null --data-binary @shakespeare.json

echo $(date +"%F %T%z") "Ending shakespeare.sh"
