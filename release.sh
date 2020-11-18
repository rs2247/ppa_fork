#!/usr/bin/env bash

########################################################################################################################
# This script performs the deploy of a Phoenix/Elixir app to a production environment.
#
# It uses a docker container (ex-builder) to compile and release the app, eliminating the need that the CI machine
# has all the Erlang/Elixir stuff installed.
#
# Initially, it was tried to use the Amazon ECR hub to host the docker image and then to pull the image in the production
# machine, but this strategy was considered impracticable due to the low download speed in the Amazon link
# (it was taking several minutes to pull the image).
#
# This script logs in the production machine and perform the following steps:
#   - copy credential to the production environment
#   - do a git pull from master to update the code repository
#   - build/update the ExBuilder image (the one responsible by building the release)
#   - run the release
#   - build/update the production image
#   -
#
# Requirements to run this script:
#
# - Edit the constants below according to your production environment.
# - Your production machine MUST have installed the awscli (only when using `docker push/pull`)
#     (guide to install: https://docs.aws.amazon.com/pt_br/cli/latest/userguide/installing.html).
# - The script must run from/in the CI machine (e.g. Jenkins) and this machine MUST have a valid AWS access configuration.
# - The production machine MUST have docker installed and running without sudo
#      (guide to install: https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository)
#
########################################################################################################################

set -e # Exit immediately if a command exits with a non-zero status.

# Input parameters
rebuild=0
skip=0
env=prod
key=""
host=""

#-----------------------------------------------------------------------------
# Constants
APP="ppa"
BRANCH="master"
ECRHOME="192794643714.dkr.ecr.us-east-1.amazonaws.com"
PROD_HOST="parcerias.querobolsa.space"
PROD_USER="redealumni"
PROD_PORT="22"
IMAGE_NAME=$APP:latest
IMG_REMOTE=$ECRHOME/$IMAGE_NAME
CONTAINER_NAME="$APP"_"$env"


#-----------------------------------------------------------------------------
# Auxiliary functions

show-help() {
	echo "Usage: $SCRIPT -h <host> -k <ssh-key> [-r] [-e <env>]
-h <host>		host to deploy
-s 			skip release build (overrides -r) and try to use the last built image
-e <env>		set different environment
-k <ssh-key>		path for key to access server"
}


#
# Pushes the docker production image to Amazon ECR docker hub, so we can pull it in the production machine.
#
dkpush() {
  echo ">>> Authenticating on AWS ECR..."
  aws ecr get-login --region us-east-1 --no-include-email --profile=default | sh
  echo ">>> Pushing docker image $IMG_REMOTE ..."
  docker tag $IMAGE_NAME $IMG_REMOTE
  docker push $IMG_REMOTE
}

#
# Copy the required files to the production machine using ssh/scp.
#
copy_files_to_production_machine() {
  echo ">>> Copying AWS credentials to production machine..."
  scp -P $port -r ~/.aws $username@$host:~/

  echo ">>> Copying APP configurations to production machine..."
  scp -P $port ./app_prod.env $username@$host:~/

  echo ">>> Files copied with success"
}

#
# Connect in the production machine, pulls the docker image and start the production app
#
run_remote_commands() {
  ssh -p $port -o StrictHostKeyChecking=no  -T $username@$host << EOF

    #
    # Uses docker to build the ex-builder image, which is responsible by releasing the application.
    #
    build_builder_image() {
      echo ">>> Rebuilding/updating ex-builder image..."
      docker build -t ex-builder -f Dockerfile.exbuilder ./
      echo ">>> ex-builder image ready"
    }

    #
    # Run the release task using the ex-builder container (which runs mix release).
    #
    run_release() {
      echo ">>> Running release..."

      # Caches the hex and node packages
      mkdir -p \$CURR_DIR/ex-builder/tmp/packages/hex && mkdir -p \$CURR_DIR/node_modules && mkdir -p \$CURR_DIR/deps && mkdir -p \$CURR_DIR/_build

      # run the release container
      docker run \
        -v \$CURR_DIR/ex-builder/tmp/packages/hex:/root/.hex/packages \
        -v \$CURR_DIR/node_modules:/app/node_modules \
        -v \$CURR_DIR/_build/prod/rel:/app/_build/prod/rel \
        -v \$CURR_DIR/priv/static:/app/priv/static \
        -v \$CURR_DIR/deps:/app/deps \
        --env-file ~$username/app_prod.env \
        --rm \
        ex-builder bash -c 'mix release_build && mix ecto.migrate -r Ppa.Repo'

      echo ">>> Build finished!"
    }

    #
    # Check that the production environment has all the required environment variables set
    #
    check_required_variables() {
      # list of environment variables required to exist in the production machine
      declare -a REQUIRED_ENV_VARS=("APP_PORT" "BI_DB_DATABASE" "BI_DB_HOST" "BI_DB_PORT" "PPA_DB_USER" "PPA_DB_HOST" "SECRET_KEY_BASE" )

      echo ">>> Checking required environment variables"
      for env_var in "\${REQUIRED_ENV_VARS[@]}"
      do
        if [ -z \${!env_var} ]; then
          echo ">>> Required environment variable not set: \$env_var. The process will be interrupted"
          exit 1
        fi
      done
    }

    #
    # Build the production image using docker.
    # The image name is defined by the $IMAGE_NAME constant.
    #
    build_production_app_image() {
      echo ">>> Building application image..."
      docker build -t $IMAGE_NAME -f Dockerfile.prod ./
      echo ">>> Production image built!"
    }

    remove_build_image() {
      echo \$(docker images | grep ex-builder | tr -s ' ' | cut -d ' ' -f 3)
      docker rmi \$(docker images | grep ex-builder | tr -s ' ' | cut -d ' ' -f 3)
    }

    echo ">>> Connected to production machine"

    docker system prune --force
    remove_build_image
    source ~/app_prod.env
    check_required_variables

    if [[ $skip -eq 0 ]]; then
      cd $APP
      sudo rm -rf _build
      CURR_DIR=\$(pwd)
      echo ">>> Current Dir: \$CURR_DIR"
      git pull origin $BRANCH
      git reset --hard

      build_builder_image
      run_release
      remove_build_image
      build_production_app_image
    else
      echo ">>> Skipping build process. The last build image will be used"
    fi

    echo ">>> Stopping running container '$CONTAINER_NAME'..."
    docker stop $CONTAINER_NAME
		echo ">>> Removing container '$CONTAINER_NAME'..."
		docker rm $CONTAINER_NAME
    echo ">>> Starting production container '$CONTAINER_NAME'"
    docker run --restart unless-stopped --name $CONTAINER_NAME \
      -v \$PPT_GENERATOR_SHARED_PATH:/shared \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /usr/bin/docker:/usr/bin/docker \
      -v /var/log/ppa:/ppa/var/log \
      --env-file ~/app_prod.env \
      -p \$APP_PORT:4000 \
      -d $IMAGE_NAME /bin/bash -c "./bin/$APP foreground" \
      && echo ">>> $APP container started at port \$APP_PORT (You should check...)"
EOF
}

#-------------------------------------------------------------------------------
# Main routine

# Read the command line input parameters and set their values on script-scoped variables.
while getopts "rsu:p:h:e:k:" setting; do
  case "$setting" in
    r)
      rebuild=1
      ;;
    s)
      skip=1
      ;;
    e)
      env=$OPTARG
      ;;
    k)
      key=$OPTARG
      ;;
    h)
      host=$OPTARG
      ;;
		u)
      username=$OPTARG
      ;;
		p)
      port=$OPTARG
      ;;
    *)
      show-help && exit 1
  esac
done

if [[ -z $host ]]; then
  echo ">>> No host provided.. Using default production host: '$PROD_HOST'"
  host=$PROD_HOST
fi
if [[ -z $port ]]; then
  echo ">>> No port provided.. Using default production port: '$PROD_PORT'"
  port=$PROD_PORT
fi
if [[ -z $username ]]; then
  echo ">>> No user provided.. Using default production user: '$PROD_USER'"
  username=$PROD_USER
fi
copy_files_to_production_machine
run_remote_commands
echo ">>> Release finished with success"
