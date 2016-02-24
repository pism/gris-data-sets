#!/bin/bash

set -x -e

infile=IBCAO_V3_500m_RR_tif
wget -nc http://www.ngdc.noaa.gov/mgg/bathymetry/arctic/grids/version3_0/${infile}.zip
unzip -o ${infile}.zip
