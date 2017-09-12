DROP TABLE IF EXISTS flightIDs;

CREATE TABLE flightIDs (
  id Char(16) PRIMARY KEY,
  flightCode Char(8),
  date Char(10)
);