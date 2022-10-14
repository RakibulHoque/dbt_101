#!/bin/bash
DEPLOYMENT=${1:-"local"}
BQ_KEY_FILE=${2:-"keyfile.json"}
DBT_FOLDER=${3:-"_101"}

# EXECUTION_DIRECTORY=$(dirname $(realpath $0))
EXECUTION_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"     # written this way for windows
cd $EXECUTION_DIRECTORY

case $DEPLOYMENT in
    prod)
    ROOT_PROJECT_DIR=/src
    DOT_ENV_FILE=$EXECUTION_DIRECTORY/.env.$DEPLOYMENT
    DBT_SERVICE_JSON=$ROOT_PROJECT_DIR/.gcloud/prod-$BQ_KEY_FILE
    ;;
    stage)
    ROOT_PROJECT_DIR=/src
    DOT_ENV_FILE=$EXECUTION_DIRECTORY/.env.$DEPLOYMENT
    DBT_SERVICE_JSON=$ROOT_PROJECT_DIR/.gcloud/stage-$BQ_KEY_FILE
    ;;
    *)
    ROOT_PROJECT_DIR=$EXECUTION_DIRECTORY
    DOT_ENV_FILE=$ROOT_PROJECT_DIR/.env.$DEPLOYMENT
    DBT_SERVICE_JSON=$ROOT_PROJECT_DIR/.gcloud/stage-$BQ_KEY_FILE
esac

DBT_PROJECT_DIR=$ROOT_PROJECT_DIR/$DBT_FOLDER
DBT_PROFILES_DIR=$DBT_PROJECT_DIR/profile




function log() {
    echo -e "$(date +"%Y-%m-%dT%H:%M:%S%z") INFO $@"
}

function warn() {
    echo -e "$(date +"%Y-%m-%dT%H:%M:%S%z") WARNING $@"
}

function error() {
    echo -e "$(date +"%Y-%m-%dT%H:%M:%S%z") ERROR $@"
    exit 1
}

function get_gcloud_active_user() {
  case $DEPLOYMENT in
    local|dev)
        GCLOUD_ACTIVE_EMAIL=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
        DEVELOPER_NAME="${GCLOUD_ACTIVE_EMAIL%@*}"
        DEVELOPER_PREFIX="$(echo "$DEVELOPER_NAME" | tr "." "_")"
        log "Retrieved gcloud active user - $DEVELOPER_NAME (from email:$GCLOUD_ACTIVE_EMAIL)"
      ;;
    qa)
        GCLOUD_ACTIVE_EMAIL=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
        DEVELOPER_NAME="${GCLOUD_ACTIVE_EMAIL%@*}"
        DEVELOPER_PREFIX="qa_$(echo "$DEVELOPER_NAME" | tr "." "_")"
        log "Retrieved gcloud active user - $DEVELOPER_NAME (from email:$GCLOUD_ACTIVE_EMAIL)"
      ;;
    stage|prod)
        DEVELOPER_PREFIX="default_$DEPLOYMENT"
        log "setting default developer_prefix: $DEVELOPER_PREFIX"
      ;;
    *)
        error "Invalid deployment $DEPLOYMENT. It must be within [local, stage, dev, qa, prod]"
  esac
}

function create_dot_env() {
  if [ -f "$DOT_ENV_FILE" ]
    then
      warn "$DOT_ENV_FILE file already exists."
      warn "Overwriting the existing $DOT_ENV_FILE file."
  fi
  (
      echo "DEPLOYMENT=$DEPLOYMENT"
      echo "ROOT_PROJECT_DIR=$ROOT_PROJECT_DIR"
      echo "DBT_PROJECT_DIR=$DBT_PROJECT_DIR"
      echo "DBT_PROFILES_DIR=$DBT_PROFILES_DIR"
      echo "DBT_SERVICE_JSON=$DBT_SERVICE_JSON"
      echo "DEVELOPER_PREFIX=$DEVELOPER_PREFIX"
  ) > "$DOT_ENV_FILE"
  log "$DOT_ENV_FILE file created"
}

function create_python_venv() {
      if [ -d "$ROOT_PROJECT_DIR/venv" ]
      then
          log "Directory $ROOT_PROJECT_DIR/venv exists."
      else
          log "Creating virtual environment"
          python3 -m venv venv
          log "Virtual environment created"
      fi
      log "Activating virtual environment"
      source venv/bin/activate
      log "Virtual environment activated successfully, Now installing requirements..."
      pip install -r requirements.txt
      log "Requirements installed successfully"
}

get_gcloud_active_user &&
case $DEPLOYMENT in
  local|dev|qa)
    create_python_venv
    ;;
  stage|prod)
      log "stage|dev|prod do not require virtual environment creation."
    ;;
    *)
      error "Invalid deployment $DEPLOYMENT. It must be within [local, stage, dev, qa, prod]"
esac &&
create_dot_env &&
case $DEPLOYMENT in
  prod)
    export_env_file="$EXECUTION_DIRECTORY/.env.prod"
    ;;
  *)
    export_env_file="$DOT_ENV_FILE"
esac &&
if [ -f "$export_env_file" ]
  then
  # shellcheck disable=SC2046
  export $(xargs < "$export_env_file")
  log "Exported below mentioned environment variables.\n\n$(cat "$export_env_file")\n
  Congratulations, setup process completed."
else
  error "Failed to export environment variables. $export_env_file file does not exist. for prod, stage must be invoked before prod."
fi