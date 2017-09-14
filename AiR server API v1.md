# AiR server API v1

All calls to the API must specify the version string of the API: `/api/v1`. The following calls are appended to this string.

## Flight registration

When the user has entered their flight code and date, this is registered into the server’s database, and the user receives a unique ID for this user-flight pair. Once this is done, the server will immediately begin preparing the data for the flight.

### `/register` (POST)

Parameter | Type | Description
---|---|---
date | String | The date of the flight, in the format `YYYY-MM-DD`
flightNumber | String | The IATA  flight designator, in the format of `xx(a)n(n)(n)(n)(a)`: the 2 or 3 character IATA airline designator, followed by the flight number (up to 4 digits), and finally an operational suffix. The regex for this is `/([A-Z]{3})([0-9]{1,4})([A-Za-z]?)/`.

##### Response

A single string, encoded in `text/plain`, representing the user-flight pair. This will be required for every subsequent message, so the client must store this.

##### Errors

- 400 Bad Request. Encoded in JSON:
	- `{ "code": 1, "string": "Bad date" }`
	- `{ "code": 2, "string": "Bad flight number" }`

### `/fetch/<id>` (GET)

Parameter | Type | Description
---|---|---
id | String | The user-flight pair

##### Response

All the data. Format TBD.

##### Errors

- 403 Forbidden: bad ID.

- 503 Service Unavailable. Encoded in JSON:
	- `{ "progress": `float` }`
	  	 where float is a number between 0 and 1, representing how ready the data is.

### `/reload/<id>` (GET)

Parameter | Type | Description
---|---|---
id | String | The user-flight pair

##### Response

202 Accepted. Blank

##### Errors

- 403 Forbidden: bad ID.

### `/refetch/<id>` (GET)

Parameter | Type | Description
---|---|---
id | String | The user-flight pair

##### Response

All the data. Format TBD.

##### Errors

- 403 Forbidden: bad ID.

- 503 Service Unavailable. Encoded in JSON:
	- `{ "progress": `float` }`
	  	 where float is a number between 0 and 1, representing how ready the data is.
