@echo off
set /p InputFile="File to convert: "
echo "*** Copying file..."
copy %InputFile% tmp.sqlite

echo "*** Moving ATAK table"
ogrinfo tmp.sqlite -sql "ALTER TABLE 'tiles' RENAME TO 'ATAK_tiles'"

echo "*** Creating MBTILES Table"
ogrinfo tmp.sqlite -sql "CREATE TABLE tiles (zoom_level INTEGER NOT NULL,tile_column INTEGER NOT NULL,tile_row INTEGER NOT NULL,tile_data BLOB NOT NULL,UNIQUE (zoom_level, tile_column, tile_row) )"

FOR /L %%I IN (0,1,20) DO (
	echo "*** Converting Level %%I"
	rem https://github.com/deptofdefense/AndroidTacticalAssaultKit-CIV/blob/0d5810815b1c6b060cb91d57ef4fefae9d7568b7/atak/ATAKMapEngine/lib/src/main/java/com/atakmap/map/layer/raster/osm/OSMUtils.java#L145
	ogrinfo tmp.sqlite -sql "INSERT INTO 'tiles' WITH const AS (SELECT %%I AS level) SELECT const.level AS zoom_level, (key >> const.level & (2<<(const.level-1))-1) AS tile_column, (1<<const.level)-1-(key & (2<<(const.level-1))-1) AS tile_row, ATAK_tiles.tile AS tile_data FROM ATAK_tiles, const WHERE (key >> const.level*2) = const.level"
	rem ogrinfo tmp.sqlite -sql "DELETE FROM 'tiles' WHERE (key >> %%I*2) = %%I"
)

echo "*** Drop old ATAK table"
ogrinfo tmp.sqlite -sql "DROP TABLE 'ATAK_tiles'"

echo "*** Create Metadata for MBtiles"
ogrinfo tmp.sqlite -sql "CREATE TABLE metadata(name TEXT, value TEXT)"
ogrinfo tmp.sqlite -sql "INSERT INTO metadata VALUES('name', 'my_tileset')"
ogrinfo tmp.sqlite -sql "INSERT INTO metadata VALUES('type', 'overlay')"
ogrinfo tmp.sqlite -sql "INSERT INTO metadata VALUES('version', '1.1')"
ogrinfo tmp.sqlite -sql "INSERT INTO metadata VALUES('description', 'description')"
ogrinfo tmp.sqlite -sql "INSERT INTO metadata VALUES('format', 'PNG')"


echo "*** Setting up Geopackage Tables"

echo "*** Create gpkg_geometry_columns"
ogrinfo tmp.sqlite -sql "CREATE TABLE gpkg_geometry_columns (table_name TEXT NOT NULL,column_name TEXT NOT NULL,geometry_type_name TEXT NOT NULL,srs_id INTEGER NOT NULL,z TINYINT NOT NULL,m TINYINT NOT NULL,CONSTRAINT pk_geom_cols PRIMARY KEY (table_name, column_name),CONSTRAINT uk_gc_table_name UNIQUE (table_name),CONSTRAINT fk_gc_tn FOREIGN KEY (table_name) REFERENCES gpkg_contents(table_name),CONSTRAINT fk_gc_srs FOREIGN KEY (srs_id) REFERENCES gpkg_spatial_ref_sys (srs_id))"
echo "*** Create gpkg_ogr_contents"
ogrinfo tmp.sqlite -sql "CREATE TABLE gpkg_ogr_contents(table_name TEXT NOT NULL PRIMARY KEY,feature_count INTEGER DEFAULT NULL)"

echo "*** Create and set up gpkg_spatial_ref_sys"
ogrinfo tmp.sqlite -sql "CREATE TABLE gpkg_spatial_ref_sys (srs_name TEXT NOT NULL,srs_id INTEGER NOT NULL PRIMARY KEY,organization TEXT NOT NULL,organization_coordsys_id INTEGER NOT NULL,definition  TEXT NOT NULL,description TEXT)"
ogrinfo tmp.sqlite -sql "INSERT INTO 'gpkg_spatial_ref_sys' VALUES ('WGS 84 / Pseudo-Mercator', '3857', 'EPSG', '3857', 'PROJCS[\"WGS 84 / Pseudo-Mercator\",GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AUTHORITY[\"EPSG\",\"4326\"]],PROJECTION[\"Mercator_1SP\"],PARAMETER[\"central_meridian\",0],PARAMETER[\"scale_factor\",1],PARAMETER[\"false_easting\",0],PARAMETER[\"false_northing\",0],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Easting\",EAST],AXIS[\"Northing\",NORTH],EXTENSION[\"PROJ4\",\"+proj=merc +a=6378137 +b=6378137 +lat_ts=0 +lon_0=0 +x_0=0 +y_0=0 +k=1 +units=m +nadgrids=@null +wktext +no_defs\"],AUTHORITY[\"EPSG\",\"3857\"]]', '')"

echo "*** Create and set up gpkg_contents"
ogrinfo tmp.sqlite -sql "CREATE TABLE gpkg_contents (table_name TEXT NOT NULL PRIMARY KEY,data_type TEXT NOT NULL,identifier TEXT UNIQUE,description TEXT DEFAULT '',last_change DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),min_x DOUBLE, min_y DOUBLE,max_x DOUBLE, max_y DOUBLE,srs_id INTEGER,CONSTRAINT fk_gc_r_srs_id FOREIGN KEY (srs_id) REFERENCES gpkg_spatial_ref_sys(srs_id))"
ogrinfo tmp.sqlite -sql "INSERT INTO 'gpkg_contents' VALUES ('ATAK_tiles', 'tiles', 'ATAK_tiles', 'ATAK_tiles', (SELECT strftime('%Y-%m-%dT%H:%M:%fZ','now')), '-20037508.3427892', '-20037508.3427892', '20037508.3427892', '20037508.3427892', '3857')"

echo "*** Create and set up gpkg_tile_matrix_set"
ogrinfo tmp.sqlite -sql "CREATE TABLE gpkg_tile_matrix_set (table_name TEXT NOT NULL PRIMARY KEY,srs_id INTEGER NOT NULL,min_x DOUBLE NOT NULL,min_y DOUBLE NOT NULL,max_x DOUBLE NOT NULL,max_y DOUBLE NOT NULL,CONSTRAINT fk_gtms_table_name FOREIGN KEY (table_name) REFERENCES gpkg_contents(table_name),CONSTRAINT fk_gtms_srs FOREIGN KEY (srs_id) REFERENCES gpkg_spatial_ref_sys (srs_id))"
ogrinfo tmp.sqlite -sql "INSERT INTO 'gpkg_tile_matrix_set' VALUES ('ATAK_tiles', '3857', '-20037508.3427892', '-20037508.3427892', '20037508.3427892', '20037508.3427892')"

echo "*** Create and set up gpkg_tile_matrix"
ogrinfo tmp.sqlite -sql "CREATE TABLE gpkg_tile_matrix (table_name TEXT NOT NULL,zoom_level INTEGER NOT NULL,matrix_width INTEGER NOT NULL,matrix_height INTEGER NOT NULL,tile_width INTEGER NOT NULL,tile_height INTEGER NOT NULL,pixel_x_size DOUBLE NOT NULL,pixel_y_size DOUBLE NOT NULL,CONSTRAINT pk_ttm PRIMARY KEY (table_name, zoom_level),CONSTRAINT fk_tmm_table_name FOREIGN KEY (table_name) REFERENCES gpkg_contents(table_name))"
ogrinfo tmp.sqlite -sql "INSERT INTO gpkg_tile_matrix SELECT 'ATAK_tiles' AS table_name, zoom_level, 1<<zoom_level AS matrix_width, 1<<zoom_level AS matrix_height, 256 AS tile_width, 256 AS tile_height, 156543.033928041 / (1<<zoom_level) AS pixel_x_size, 156543.033928041 / (1<<zoom_level) AS pixel_x_size FROM tiles GROUP BY zoom_level"

echo "*** Create View for Geopackage"
ogrinfo tmp.sqlite  -sql "CREATE VIEW ATAK_tiles AS SELECT ((((tiles.zoom_level << tiles.zoom_level) + tile_column) << tiles.zoom_level) + (tile_row)) AS id, tiles.zoom_level, tile_column, tm.matrix_height-1-tile_row AS tile_row, tile_data FROM tiles JOIN gpkg_tile_matrix tm ON tiles.zoom_level = tm.zoom_level AND tm.table_name = 'ATAK_tiles'"

echo "*** Optimize database"
ogrinfo tmp.sqlite -sql "VACUUM"

rem ogrinfo tmp.sqlite -sql "PRAGMA user_version=10200"
rem ogrinfo tmp.sqlite -sql "PRAGMA application_id=1196444487"

echo "*** Rename with multiple file endings"
FOR %%i IN ("%InputFile%") DO (
	MOVE tmp.sqlite %%~ni.mbtiles.gpkg
)