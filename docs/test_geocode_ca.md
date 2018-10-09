# Testing the TIGER geocoder with PostGIS for California

_Sample query_:

`exec` into the container:

```shell
sudo docker exec -it <tiger-geocoder-container> bash
>>> psql -U postgres -d geocode

```

Enter the following SQL command then:

```sql
SELECT g.rating, ST_X(g.geomout) As lon, ST_Y(g.geomout) As lat,
    (addy).address As stno, (addy).streetname As street,
    (addy).streettypeabbrev As styp, (addy).location As city, (addy).stateabbrev As st,(addy).zip
    FROM geocode('380 New York Street
Redlands, CA 92373-8100', 1) As g;

```

(executing the same command above from outside the container:

```shell
sudo docker exec <tiger-geocoder-container> psql -U postgres -d geocode -c "SELECT g.rating, ST_X(g.geomout) As lon, ST_Y(g.geomout) As lat, (addy).address As stno, (addy).streetname As street, (addy).streettypeabbrev As styp, (addy).location As city, (addy).stateabbrev As st,(addy).zip FROM geocode('380 New York Street Redlands, CA 92373-8100', 1) As g;"

```

)

_Sample response_:

```shell
rating |        lon        |       lat        | stno |  street  | styp |   city
  | st |  zip
--------+-------------------+------------------+------+----------+------+-------
---+----+-------
     0 | -117.195591834781 | 34.0570255533775 |  380 | New York | St   | Redlan
ds | CA | 92373
(1 row)

```
