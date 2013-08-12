#!/bin/bash
dmd -O -L/STACK:268435456 -wi $@ && rm ${1%%.*}.obj
