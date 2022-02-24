# Converting files to "multipass" files

A multipass file is a file that can be used as multiple fileformats by changing the file extension. Initially created to move data in and out of ATAK. https://github.com/deptofdefense/AndroidTacticalAssaultKit-CIV

1. For ATAK/WinTAK use MBTILES files
2. For ArcGIS use GPKG files

So if you get a file that is called file.mbtiles.gpkg and want to use it in ATAK/WinTAK rename it to file.mbtiles, if you want to use it in ArcGIS rename it to file.gpkg.


# Using the different scripts

- Install QGIS and open OSGeo4W Shell
- If you need to change from C: to another drive, type the drive letter and press enter, for example "G:" ENTER
- Navigate to the folder where you have your scripts by typing "CD folder"
- Choose the script you want to run

(All scripts creates a copy of the original file that the operations are made on so you won't have to be afraid to make break anything)

### atak2multipass.bat

This script is used to convert an ATAK sqlite raster cache to a multipass file.

- Run the script by typing atak2multipass.bat and press ENTER
- The script asks for what sqlite file you want to convert, type in the name of the file and press ENTER

### mbtiles2multipass.bat

This file is used to convert a MBTILES raster file to a multipass file.

NOTE You cant convert MBTILES vector files NOTE

- Run the script by typing mbtiles2multipass.bat and press ENTER

- Kör scriptet genom att skriva mbtiles2multipass.bat och trycka enter
- The script asks for what sqlite file you want to convert, type in the name of the file and press ENTER

### folder2multipass.bat

This script is used to convert a folder with images to a multipass file.

- Run the script by typing folder2multipass.bat and press ENTER
- The script asks what folder and filetype you want to convert, typ in the folder and a pattern for the files. Example C:\myfiles\*.tif
- The script asks for the name of the file that should be converted, type it in without file extension. Example C:\myfiles\mymultipassfile

### gpkg2multipass.bat

This file converts a GPKG file to a multipass file, given that you created your GPKG file with GoogleMapsCompatable tiles with GDAL.
