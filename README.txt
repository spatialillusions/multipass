# Konvertera data till "multipass" filer

För att kunna använda filer vi skapar både i ATAK/WinTAK och ArcGIS, så genererar vi något som är flera olika filformat på samma gång. Sedan väljer man vilken typ det ska vara genom att behålla den filändelse man vill ha.

1. För ATAK/WinTAK använd MBTILES filer
2. För ArcGIS använd GPKG filer

Alltså du får ut en fil som heter fil.mbtiles.gpkg, ska den användas i ATAK/WinTAK så döper du om den till fil.mbtiles, ska den användas i ArcMap döper du om den till fil.gpkg.

# Använda de olika scripten

- Öppna applikationen OSGeo4W Shell
- Behöver du byta från c: till annan disk skriv diskbokstaven följt av ett kolon och tryck enter, exempelvis "g:"
- Navigera till katalogen där du har dina script med att skriva "cd katalog"
- Välj det script du vill köra nedan 
(Alla script skapar en kopia av orginalfilen och kör alla operationer på denna för att du inte ska kunna förstöra något med dina grisklövar)

### atak2multipass.bat

Detta script används för att konvertera en ATAK sqlite raster cache till en multipass fil.

- Kör scriptet genom att skriva atak2multipass.bat och trycka enter
- Scriptet frågar efter vilken sqlite fil du vill konvertera, ange denna (tips du kan börja skriva namnet och trycka tab för att autokompletera det) tryck sedan enter

### mbtiles2multipass.bat

Detta script används för att konvertera en MBTILES RASTER fil till en multipass fil. 
OBS! Det går inte att konvertera en MBTILES VECTOR fil till multipass. OBS!

- Kör scriptet genom att skriva mbtiles2multipass.bat och trycka enter
- Scriptet frågar efter vilken mbtiles fil du vill konvertera, ange denna (tips du kan börja skriva namnet och trycka tab för att autokompletera det) tryck sedan enter

### folder2multipass.bat

Detta script används för att konvertera en katalog med bildfiler till en multipass fil.

- Kör scriptet genom att skriva folder2multipass.bat och trycka enter
- Scriptet frågar efter vilken katalog och filtyp du vill konvertera, ange denna och ett filter för filerna(tips du kan börja skriva namnet och trycka tab för att autokompletera det) tryck sedan enter
	Exempel:
		Filerna är i samma map som scriptet:
			*.tif eller *.jp2
		Filerna är i en undermapp:
			undermapp/annanmapp/*.tif
- Scriptet frågar nu efter namn på filen som ska skapas, ange ett filnamn utan filändelse. Exempelvis Sökväg/fil

### folder_expand_rgb2multipass.bat

Detta script används för att konvetera en katalog med bildfiler till en multipass fil, om bilderna innehåller en färgpalett. (Om folder2multipass ger dig en svartvit output och det inte var det du förväntade dig så är det antagligen detta script du vill köra.)

- Kör scriptet genom att skriva folder2multipass.bat och trycka enter
- Scriptet frågar efter vilken katalog och filtyp du vill konvertera, ange denna och ett filter för filerna(tips du kan börja skriva namnet och trycka tab för att autokompletera det) tryck sedan enter
	Exempel:
		Filerna är i samma map som scriptet:
			*.tif eller *.jp2
		Filerna är i en undermapp:
			undermapp/annanmapp/*.tif
- Scriptet frågar nu efter namn på filen som ska skapas, ange ett filnamn utan filändelse. Exempelvis Sökväg/fil

### gpkg2multipass.bat

Detta script conveterar en GPKG fil till en multipass fil, förutsatt att din GPKG fil skapades med GoogleMapsCompatable tiles med GDAL. Det ska du nog inte behöva göra om du inte vet exakt vad du pysslar med.

- Om du behöver köra det här så kan du nog lista ut hur du gör.
