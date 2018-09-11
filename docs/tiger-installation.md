# Installation of TIGER geocoder with PostgreSQL-PostGIS

## Prerequisites

Ensure PostgreSQL and PostGIS are installed, a database created and enabled with `postgis` and `postgis_topology` extensions.

## TIGER geocoder enabling the PostgreSQL database

This method uses extensions (supported only for PostgreSQL versions 9.1+ and PostGIS versions 2.1+). The PostGIS binaries, when installed, _automatically_ install the necessary extension files for the tiger geocoder.

### Enabling the TIGER geocoder extension

```shell
psql -d geocode -c "CREATE EXTENSION fuzzystrmatch;"
psql -d geocode -c "CREATE EXTENSION postgis_tiger_geocoder;"
psql -d geocode -c "CREATE EXTENSION address_standardizer;"

```

(_N.B._ 1: The `fuzzystrmatch` extension provides functions like `soundex`, `metaphone`, `dmetaphone` and `levenshtein`, to find similarities and distance among strings. While the former three work on phonetic similarity, the `levenshtein` function calculates distances based on dissimilarities. More on them [**here**](https://www.postgresql.org/docs/9.1/static/fuzzystrmatch.html).)

(_N.B._: The `address_standardizer` extension parses a single-line address input and normalizes it based on set rules. More on it [**here**](https://postgis.net/docs/Address_Standardizer.html).)


### Test the installation


```shell
psql -d geocode -c "SELECT na.address, na.streetname,na.streettypeabbrev, na.zip FROM normalize_address('1 Devonshire Place, Boston, MA 02109') AS na;"

```
