DROP TABLE IF EXISTS flightIDs;

CREATE TABLE flightIDs (
  id Char(16) PRIMARY KEY,
  flightCode Char(8),
  date Char(10),
  dataReady Boolean
);

DROP TABLE IF EXISTS flightPaths;

CREATE TABLE flightPaths (
  flightCode Char(8) PRIMARY KEY,
  expires Integer,
  path Text
);
