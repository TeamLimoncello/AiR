DROP TABLE IF EXISTS flightIDs;

CREATE TABLE flightIDs (
  id Char(16) PRIMARY KEY,
  flightCode Char(8),
  date Char(10),
  dataReady Boolean DEFAULT 0,
  invalid Boolean DEFAULT 0
);

DROP TABLE IF EXISTS flightPaths;

CREATE TABLE flightPaths (
  flightCode Char(8) PRIMARY KEY,
  expires Integer,
  path Text,
  origin Text,
  destination Text
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