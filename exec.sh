#!/bin/bash

if [ $EXEC_MODE = "rstudio" ]; then
    echo "Launching RStudio"
    /usr/lib/rstudio-server/bin/rserver
elif [ $EXEC_MODE = "script" ]; then
    echo "Sleeping 5 min to wait for IB connection success"
    sleep 5m
fi
