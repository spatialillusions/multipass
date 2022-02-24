@echo off
echo "*** WARNING! The Geopackage must have been made with a GoogleMapsCompatable Tiling Scheme for this to work. If you are unsure, abort."
set /p InputFile="File to convert: "
echo "*** Copying file..."
copy %InputFile% tmp.sqlite

rem Get the name of the raster table in the geopackage
FOR /F "skip=10 tokens=4" %%i IN ('ogrinfo tmp.sqlite -sql "SELECT table_name FROM gpkg_contents WHERE data_type='tiles' LIMIT 3"') DO set TABLE=%%i


echo "*** Remove Geopackage Pragma"
rem ogrinfo %output% -sql "PRAGMA user_version=0"
ogrinfo tmp.sqlite -sql "PRAGMA application_id=0"

echo "*** Creating MBTILES Table"
ogrinfo tmp.sqlite -sql "CREATE TABLE tiles (zoom_level INTEGER NOT NULL,tile_column INTEGER NOT NULL,tile_row INTEGER NOT NULL,tile_data BLOB NOT NULL,UNIQUE (zoom_level, tile_column, tile_row) )"
ogrinfo tmp.sqlite -sql "INSERT INTO 'tiles' SELECT zoom_level, tile_column, (1<<zoom_level)-1-tile_row AS tile_row, tile_data FROM %TABLE%"

rem echo "*** Create and set up gpkg_spatial_ref_sys"
rem ogrinfo %output% -sql "ALTER TABLE gpkg_spatial_ref_sys RENAME TO old_gpkg_spatial_ref_sys"
rem ogrinfo %output% -sql "CREATE TABLE gpkg_spatial_ref_sys (srs_name TEXT NOT NULL,srs_id INTEGER NOT NULL PRIMARY KEY,organization TEXT NOT NULL,organization_coordsys_id INTEGER NOT NULL,definition  TEXT NOT NULL,description TEXT)"
rem ogrinfo %output% -sql "INSERT INTO 'gpkg_spatial_ref_sys' SELECT * FROM old_gpkg_spatial_ref_sys"

echo "*** Create and set up gpkg_contents"
ogrinfo tmp.sqlite -sql "ALTER TABLE gpkg_contents RENAME TO old_gpkg_contents"
ogrinfo tmp.sqlite -sql "CREATE TABLE gpkg_contents (table_name TEXT NOT NULL PRIMARY KEY,data_type TEXT NOT NULL,identifier TEXT UNIQUE,description TEXT DEFAULT '',last_change DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),min_x DOUBLE, min_y DOUBLE,max_x DOUBLE, max_y DOUBLE,srs_id INTEGER,CONSTRAINT fk_gc_r_srs_id FOREIGN KEY (srs_id) REFERENCES gpkg_spatial_ref_sys(srs_id))"
ogrinfo tmp.sqlite -sql "INSERT INTO 'gpkg_contents' SELECT * FROM old_gpkg_contents"

echo "*** Create and set up gpkg_tile_matrix_set"
ogrinfo tmp.sqlite -sql "ALTER TABLE gpkg_tile_matrix_set RENAME TO old_gpkg_tile_matrix_set"
ogrinfo tmp.sqlite -sql "CREATE TABLE gpkg_tile_matrix_set (table_name TEXT NOT NULL PRIMARY KEY,srs_id INTEGER NOT NULL,min_x DOUBLE NOT NULL,min_y DOUBLE NOT NULL,max_x DOUBLE NOT NULL,max_y DOUBLE NOT NULL,CONSTRAINT fk_gtms_table_name FOREIGN KEY (table_name) REFERENCES gpkg_contents(table_name),CONSTRAINT fk_gtms_srs FOREIGN KEY (srs_id) REFERENCES gpkg_spatial_ref_sys (srs_id))"
ogrinfo tmp.sqlite -sql "INSERT INTO 'gpkg_tile_matrix_set' SELECT * FROM old_gpkg_tile_matrix_set"

echo "*** Create and set up gpkg_tile_matrix"
ogrinfo tmp.sqlite -sql "ALTER TABLE gpkg_tile_matrix RENAME TO old_gpkg_tile_matrix"
ogrinfo tmp.sqlite -sql "CREATE TABLE gpkg_tile_matrix (table_name TEXT NOT NULL,zoom_level INTEGER NOT NULL,matrix_width INTEGER NOT NULL,matrix_height INTEGER NOT NULL,tile_width INTEGER NOT NULL,tile_height INTEGER NOT NULL,pixel_x_size DOUBLE NOT NULL,pixel_y_size DOUBLE NOT NULL,CONSTRAINT pk_ttm PRIMARY KEY (table_name, zoom_level),CONSTRAINT fk_tmm_table_name FOREIGN KEY (table_name) REFERENCES gpkg_contents(table_name))"
ogrinfo tmp.sqlite -sql "INSERT INTO gpkg_tile_matrix SELECT * FROM old_gpkg_tile_matrix"

echo "*** Drop old Geopackage table"
rem ogrinfo %output% -sql "DROP TABLE old_gpkg_spatial_ref_sys"
ogrinfo tmp.sqlite -sql "DROP TABLE old_gpkg_contents"
ogrinfo tmp.sqlite -sql "DROP TABLE old_gpkg_tile_matrix_set"
ogrinfo tmp.sqlite -sql "DROP TABLE old_gpkg_tile_matrix"
ogrinfo tmp.sqlite -sql "DROP TABLE %TABLE%"

echo "*** Create Metadata for MBtiles"
ogrinfo tmp.sqlite -sql "CREATE TABLE metadata(name TEXT, value TEXT)"
ogrinfo tmp.sqlite -sql "INSERT INTO metadata VALUES('name', 'my_tileset')"
ogrinfo tmp.sqlite -sql "INSERT INTO metadata VALUES('type', 'overlay')"
ogrinfo tmp.sqlite -sql "INSERT INTO metadata VALUES('version', '1.1')"
ogrinfo tmp.sqlite -sql "INSERT INTO metadata VALUES('description', 'description')"
ogrinfo tmp.sqlite -sql "INSERT INTO metadata VALUES('format', 'PNG')"

echo "*** Create View for Geopackage"
ogrinfo tmp.sqlite -sql "CREATE VIEW %TABLE% AS SELECT ((((tiles.zoom_level << tiles.zoom_level) + tile_column) << tiles.zoom_level) + (tile_row)) AS id, tiles.zoom_level, tile_column, tm.matrix_height-1-tile_row AS tile_row, tile_data FROM tiles JOIN gpkg_tile_matrix tm ON tiles.zoom_level = tm.zoom_level AND tm.table_name = '%TABLE%'"



echo "*** Optimize database"
ogrinfo tmp.sqlite -sql "VACUUM"

MOVE tmp.sqlite %InputFile%.mbtiles.gpkg

