@echo off
set GDAL_CACHEMAX=16000

set /P indata="Folder/files to build file (ATAK/GPKG/MBTILES) from: (in format 'PATH/*.extension') "
set /P gpkg="File output folder/name: (in format 'PATH/file')"
set output=%gpkg%.mbtiles.gpkg

echo Building vrt
gdalbuildvrt %gpkg%.vrt %indata%

gdal_translate %gpkg%.vrt %output% -r cubic -co TILING_SCHEME=GoogleMapsCompatible -co RASTER_TABLE=ATAK_tiles -co TILE_FORMAT=PNG -expand rgb

echo Adding overviews
gdaladdo -r cubic %output%

echo "*** Remove Geopackage Pragma"
rem ogrinfo %output% -sql "PRAGMA user_version=0"
ogrinfo %output% -sql "PRAGMA application_id=0"

MOVE %output% %gpkg%.sqlite

echo "*** Creating MBTILES Table"
ogrinfo %gpkg%.sqlite -sql "CREATE TABLE tiles (zoom_level INTEGER NOT NULL,tile_column INTEGER NOT NULL,tile_row INTEGER NOT NULL,tile_data BLOB NOT NULL,UNIQUE (zoom_level, tile_column, tile_row) )"
ogrinfo %gpkg%.sqlite -sql "INSERT INTO 'tiles' SELECT zoom_level, tile_column, (1<<zoom_level)-1-tile_row AS tile_row, tile_data FROM ATAK_tiles"

rem echo "*** Create and set up gpkg_spatial_ref_sys"
rem ogrinfo %output% -sql "ALTER TABLE gpkg_spatial_ref_sys RENAME TO old_gpkg_spatial_ref_sys"
rem ogrinfo %output% -sql "CREATE TABLE gpkg_spatial_ref_sys (srs_name TEXT NOT NULL,srs_id INTEGER NOT NULL PRIMARY KEY,organization TEXT NOT NULL,organization_coordsys_id INTEGER NOT NULL,definition  TEXT NOT NULL,description TEXT)"
rem ogrinfo %output% -sql "INSERT INTO 'gpkg_spatial_ref_sys' SELECT * FROM old_gpkg_spatial_ref_sys"

echo "*** Create and set up gpkg_contents"
ogrinfo %gpkg%.sqlite -sql "ALTER TABLE gpkg_contents RENAME TO old_gpkg_contents"
ogrinfo %gpkg%.sqlite -sql "CREATE TABLE gpkg_contents (table_name TEXT NOT NULL PRIMARY KEY,data_type TEXT NOT NULL,identifier TEXT UNIQUE,description TEXT DEFAULT '',last_change DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),min_x DOUBLE, min_y DOUBLE,max_x DOUBLE, max_y DOUBLE,srs_id INTEGER,CONSTRAINT fk_gc_r_srs_id FOREIGN KEY (srs_id) REFERENCES gpkg_spatial_ref_sys(srs_id))"
ogrinfo %gpkg%.sqlite -sql "INSERT INTO 'gpkg_contents' SELECT * FROM old_gpkg_contents"

echo "*** Create and set up gpkg_tile_matrix_set"
ogrinfo %gpkg%.sqlite -sql "ALTER TABLE gpkg_tile_matrix_set RENAME TO old_gpkg_tile_matrix_set"
ogrinfo %gpkg%.sqlite -sql "CREATE TABLE gpkg_tile_matrix_set (table_name TEXT NOT NULL PRIMARY KEY,srs_id INTEGER NOT NULL,min_x DOUBLE NOT NULL,min_y DOUBLE NOT NULL,max_x DOUBLE NOT NULL,max_y DOUBLE NOT NULL,CONSTRAINT fk_gtms_table_name FOREIGN KEY (table_name) REFERENCES gpkg_contents(table_name),CONSTRAINT fk_gtms_srs FOREIGN KEY (srs_id) REFERENCES gpkg_spatial_ref_sys (srs_id))"
ogrinfo %gpkg%.sqlite -sql "INSERT INTO 'gpkg_tile_matrix_set' SELECT * FROM old_gpkg_tile_matrix_set"

echo "*** Create and set up gpkg_tile_matrix"
ogrinfo %gpkg%.sqlite -sql "ALTER TABLE gpkg_tile_matrix RENAME TO old_gpkg_tile_matrix"
ogrinfo %gpkg%.sqlite -sql "CREATE TABLE gpkg_tile_matrix (table_name TEXT NOT NULL,zoom_level INTEGER NOT NULL,matrix_width INTEGER NOT NULL,matrix_height INTEGER NOT NULL,tile_width INTEGER NOT NULL,tile_height INTEGER NOT NULL,pixel_x_size DOUBLE NOT NULL,pixel_y_size DOUBLE NOT NULL,CONSTRAINT pk_ttm PRIMARY KEY (table_name, zoom_level),CONSTRAINT fk_tmm_table_name FOREIGN KEY (table_name) REFERENCES gpkg_contents(table_name))"
ogrinfo %gpkg%.sqlite -sql "INSERT INTO gpkg_tile_matrix SELECT * FROM old_gpkg_tile_matrix"

echo "*** Drop old Geopackage table"
rem ogrinfo %output% -sql "DROP TABLE old_gpkg_spatial_ref_sys"
ogrinfo %gpkg%.sqlite -sql "DROP TABLE old_gpkg_contents"
ogrinfo %gpkg%.sqlite -sql "DROP TABLE old_gpkg_tile_matrix_set"
ogrinfo %gpkg%.sqlite -sql "DROP TABLE old_gpkg_tile_matrix"
ogrinfo %gpkg%.sqlite -sql "DROP TABLE ATAK_tiles"

echo "*** Create Metadata for MBtiles"
ogrinfo %gpkg%.sqlite -sql "CREATE TABLE metadata(name TEXT, value TEXT)"
ogrinfo %gpkg%.sqlite -sql "INSERT INTO metadata VALUES('name', 'my_tileset')"
ogrinfo %gpkg%.sqlite -sql "INSERT INTO metadata VALUES('type', 'overlay')"
ogrinfo %gpkg%.sqlite -sql "INSERT INTO metadata VALUES('version', '1.1')"
ogrinfo %gpkg%.sqlite -sql "INSERT INTO metadata VALUES('description', 'description')"
ogrinfo %gpkg%.sqlite -sql "INSERT INTO metadata VALUES('format', 'PNG')"

echo "*** Create View for Geopackage"
ogrinfo %gpkg%.sqlite -sql "CREATE VIEW ATAK_tiles AS SELECT ((((tiles.zoom_level << tiles.zoom_level) + tile_column) << tiles.zoom_level) + (tile_row)) AS id, tiles.zoom_level, tile_column, tm.matrix_height-1-tile_row AS tile_row, tile_data FROM tiles JOIN gpkg_tile_matrix tm ON tiles.zoom_level = tm.zoom_level AND tm.table_name = 'ATAK_tiles'"



echo "*** Optimize database"
ogrinfo %gpkg%.sqlite -sql "VACUUM"

MOVE %gpkg%.sqlite %output%

