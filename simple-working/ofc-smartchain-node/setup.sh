#!/bin/bash
git submodule init
git submodule update --init --recursive

# This repo relies on docker-compose .env variables to be set
# & accessible to bash env
#############################################################
# For complete list, please refer to .env.sample
#############################################################
