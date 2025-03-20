#!/bin/sh

echo "copy platys-mdp-init scripts"
cp -rv ./infra/init/* $DATAPLATFORM_HOME/init/platys-mdp-init

echo "copy data"
cp -rv ./data/* $DATAPLATFORM_HOME/data-transfer
