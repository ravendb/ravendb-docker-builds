#!/bin/bash 

set -e

# original usage
# S3Uploader.exe [category] [buildVersion] [filename] [comment]

# settings file
#
# UrlToPostTo = ConfigurationManager.AppSettings["UrlToPostTo"],
# SecretPass = ConfigurationManager.AppSettings["SecretPass"],
# BucketName = ConfigurationManager.AppSettings["BucketName"],
# AwsAccessKey = ConfigurationManager.AppSettings["AwsAccessKey"],
# AwsSecretKey = ConfigurationManager.AppSettings["AwsSecretKey"],
#

function checkRequiredVars {
    local varname=$1
    for varname in "$@"; do
        if [ -z "${!varname}" ]; then
            echo "Required environment variable $varname is not set."
            exit 1
        fi
    done
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --dry-run)
    DRY_RUN=1
    shift # past argument
    ;;
    --category)
    CATEGORY="$2"
    shift # past argument
    shift # past value
    ;;
    --build-version|--build-number)
    BUILD_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --filename|-f)
    FILEPATH="$2"
    shift # past argument
    shift # past value
    ;;
    --comment)
    COMMENT="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


checkRequiredVars BUCKET_NAME AWS_SECRET_ACCESS_KEY AWS_ACCESS_KEY_ID SECRET_PASS \
	BUILD_VERSION CATEGORY FILEPATH COMMENT

if [ ! -f "$FILEPATH" ]; then
  echo "File $FILEPATH does not exist."
  exit 1
fi

function wrapExec () {
  if [ -z "$DRY_RUN" ]; then
    echo "Execute: $@"
    
    "$@"

    if [ $? -ne 0 ]; then
      echo "Command failed. See errors above."
      exit 1
    fi
  else
    echo "DRYRUN: $@"
  fi
}

if [ ! -z "$DRY_RUN" ]; then
  echo "Running DRY RUN"
fi

API_HR_COM__URL="${API_HR_COM__URL:-https://api.hibernatingrhinos.com}"
CATEGORY_URLENCODED=$(echo -n "$CATEGORY" | jq -sRr @uri)
API_HR_COM__DOWNLOADS_PATH="/api/v1/downloads/${CATEGORY_URLENCODED}/${BUILD_VERSION}"
API_HR_COM__REGISTER_DL_URL="${API_HR_COM__URL}${API_HR_COM__DOWNLOADS_PATH}"

FILENAME=$(basename $FILEPATH)
wrapExec aws s3 cp $FILEPATH s3://${BUCKET_NAME}/
wrapExec aws s3api put-object-acl --region "${AWS_DEFAULT_REGION}" --bucket "${BUCKET_NAME}" --key "${FILENAME}" --acl public-read 

DOWNLOAD_URL="https://daily-builds.s3.amazonaws.com/${FILENAME}"
echo "Download URL is: $DOWNLOAD_URL"

# wrapExec curl -vvv -X PUT \
#    --data-urlencode "downloadUrl=$DOWNLOAD_URL" \
#    --data-urlencode "comment=$COMMENT" \
#    --data-urlencode "secretPass=$SECRET_PASS" \
#   "$API_HR_COM__REGISTER_DL_URL"
