#!/bin/bash -e -o pipefail
################################################################################
##  File:  install-php.sh
##  Desc:  Install PHP
################################################################################

source ~/utils/utils.sh

echo Installing PHP
phpVersionToolset=$(get_toolset_value '.php.version')
brew_smart_install "php@${phpVersionToolset}"

echo Installing composer
brew_smart_install "composer"

invoke_tests "PHP"
