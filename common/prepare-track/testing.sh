DATE=$(date +%s)
TIMETO=$(( $DATE ))
TIMETO=${TIMETO%?}
TIMETO+=0
TIMEFROM=$(( $TIMETO - 100 ))
TIMETO=$(( $TIMETO + 100 ))
#echo "DATE: " $DATE "TIMETO: " $TIMETO "TIMEFROM: " $TIMEFROM
TIMETO+=000000
TIMEFROM+=000000
cp /Users/pablopez/GIT/instruqt-assets/common/prepare-track/new_data.original.json /Users/pablopez/GIT/instruqt-assets/common/prepare-track/data.json
sed -i -e 's/"_TO"/'"$TIMETO"'/g' /Users/pablopez/GIT/instruqt-assets/common/prepare-track/data.json
sed -i -e 's/"_FROM"/'"$TIMEFROM"'/g' /Users/pablopez/GIT/instruqt-assets/common/prepare-track/data.json

curl -H "Content-Type: application/json"\
    -H 'Authorization: Bearer [REDACTED]' \
    --request POST \
    --data @./data.json \
    "https://app.sysdigcloud.com//api/data/entity/metadata" #\
# | jq
