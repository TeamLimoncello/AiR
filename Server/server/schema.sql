DROP TABLE IF EXISTS flightIDs;

CREATE TABLE flightIDs (
  id Char(16) PRIMARY KEY,
  flightCode Char(8),
  date Char(10),
  departureTime Int,
  dataReady Boolean DEFAULT 0,
  invalid Text,
  tiles Int,
  loaded Int DEFAULT 0
);

DROP TABLE IF EXISTS flightPaths;

CREATE TABLE flightPaths (
  flightCode Char(8) PRIMARY KEY,
  expires Integer,
  path Text,
  origin Text,
  originCode Char(3),
  originLat Float,
  originLong Float,
  destination Text,
  destinationCode Char(3),
  destinationLat Float,
  destinationLong Float
);

DROP TABLE IF EXISTS cities;

CREATE TABLE cities (
  id Integer PRIMARY KEY AUTOINCREMENT,
  name Text,
  population Integer,
  lat Float,
  long Float,
  name_en Text
);

DROP TABLE IF EXISTS tiles;

CREATE TABLE tiles (
  file Text PRIMARY KEY,
  id Char(16),
  alat Float,
  along Float,
  blat Float,
  blong Float,
  tag Text
);
