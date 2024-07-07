#!/usr/bin/env bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  echo "You don't need to source this script ... Please try './setup.sh'."
else
  docker build -t cac-with-ansible:1.0.0 docker-setup \
    && docker network create cac || true \
    && docker container run --name app -d -t -p 9000:8080 --network cac cac-with-ansible:1.0.0  \
    && docker container run --name web -d -t -p 8080:80   --network cac cac-with-ansible:1.0.0  \
    && docker container ls \
    && cat << "EOF"
#####################################
8888888b.
888  "Y88b
888    888
888    888  .d88b.  88888b.   .d88b.
888    888 d88""88b 888 "88b d8P  Y8b
888    888 888  888 888  888 88888888
888  .d88P Y88..88P 888  888 Y8b.
8888888P"   "Y88P"  888  888  "Y8888
#####################################
EOF
fi
