#!/bin/bash

set -x -e

infile=MCdataset-2015-04-27.nc
if [ -n "$1" ]; then
    infile=$1
fi

wget -nc ftp://sidads.colorado.edu/DATASETS/IDBMG4_BedMachineGr/$infile


ver=2_ibcao
if [ -n "$2" ]; then
    ver=$2
fi

# Create a buffer that is a multiple of the grid resolution
# and works for grid resolutions up to 36km.
buffer_x=40650
buffer_y=22000
xmin=$((-638000 - $buffer_x))
ymin=$((-3349600 - $buffer_y))
xmax=$((864700 + $buffer_x))
ymax=$((-657600 + $buffer_y))

outfile=Greenland_150m_mcb_jpl_v${ver}.nc
GRID=150

for var in "bed" "errbed"; do
    rm -f g${GRID}m_${var}_v${ver}.tif g${GRID}m_${var}_v${ver}.nc
    gdalwarp -overwrite  -srcnodata -9999 -dstnodata -2000 -r average -s_srs EPSG:3413 -t_srs EPSG:3413 -te $xmin $ymin $xmax $ymax -tr $GRID $GRID -of GTiff NETCDF:$infile:$var g${GRID}m_${var}_v${ver}.tif
    gdalwarp -overwrite -of netCDF -srcnodata -2000  -dstnodata -2000 -s_srs EPSG:3413 -t_srs EPSG:3413 g${GRID}m_${var}_v${ver}.tif g${GRID}m_${var}_v${ver}.nc 
    ncatted -a nx,global,d,, -a ny,global,d,, -a xmin,global,d,, -a ymax,global,d,, -a spacing,global,d,, g${GRID}m_${var}_v${ver}.nc
    ncrename -O -v Band1,$var g${GRID}m_${var}_v${ver}.nc g${GRID}m_${var}_v${ver}.nc
done
for var in "surface" "thickness"; do
    rm -f g${GRID}m_${var}_v${ver}.tif g${GRID}m_${var}_v${ver}.nc
    gdalwarp -overwrite -r average -te $xmin $ymin $xmax $ymax -tr $GRID $GRID -of GTiff NETCDF:$infile:$var g${GRID}m_${var}_v${ver}.tif
    # gdalwarp -overwrite -r average -te $xmin $ymin $xmax $ymax -tr $GRID $GRID -of netCDF NETCDF:$infile:$var g${GRID}m_${var}_v${ver}.nc
    gdalwarp -overwrite -of netCDF -s_srs EPSG:3413 -t_srs EPSG:3413  g${GRID}m_${var}_v${ver}.tif g${GRID}m_${var}_v${ver}.nc 
    ncrename -O -v Band1,$var g${GRID}m_${var}_v${ver}.nc g${GRID}m_${var}_v${ver}.nc
    ncap2 -O -s "where(${var}<=0) ${var}=0.;" g${GRID}m_${var}_v${ver}.nc g${GRID}m_${var}_v${ver}.nc
done
for var in "mask" "source"; do
    rm -f g${GRID}m_${var}_v${ver}.tif g${GRID}m_${var}_v${ver}.nc
    gdalwarp -overwrite -r near -te $xmin $ymin $xmax $ymax -tr $GRID $GRID -of GTiff NETCDF:$infile:$var g${GRID}m_${var}_v${ver}.tif
    # gdalwarp -overwrite -r near -te $xmin $ymin $xmax $ymax -tr $GRID $GRID -of netCDF NETCDF:$infile:$var g${GRID}m_${var}_v${ver}.nc
    gdalwarp -overwrite -of netCDF -s_srs EPSG:3413 -t_srs EPSG:3413 -of netCDF g${GRID}m_${var}_v${ver}.tif g${GRID}m_${var}_v${ver}.nc 
    ncrename -O -v Band1,$var g${GRID}m_${var}_v${ver}.nc g${GRID}m_${var}_v${ver}.nc
done



ncks -O  $infile $outfile
ncatted -a _FillValue,bed,d,, $outfile
ncap2 -O -s "where(mask==3) bed=-9999" $outfile $outfile

# This is not needed, but it can be used by PISM to calculate correct cell volumes, and for remapping scripts"
ncatted -a proj4,global,o,c,"+init=epsg:3413" $outfile
