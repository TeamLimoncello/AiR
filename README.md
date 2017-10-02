# AiR

AiR is a travel app for iOS devices developed by Bristol based development team Limoncello. It aims to use Augmented Reality to take flyers out of their seats and into the sky. Data from the ESA's Copernicus Satellite program is used to display an interactive projection of the world to the user, letting them see information about the cities and landmarks they pass over during their flight, without the disruptions of clouds or the plane getting in the way. The app came out of the team's participation in the Copernicus Space App Camp organised by the ESA and supported by AZO and RAMANI.

![Screenshot](https://scontent-amt2-1.xx.fbcdn.net/v/t35.0-12/21845430_1599599636726957_1030835351_o.jpg?oh=0de6fe7119517f812f2ed1adbac40119&oe=59C07E7D)

The project consists of an iOS app written in Swift using [ARKit](https://developer.apple.com/arkit/), plus a backend written in python. The stack consists of a [Flask](http://flask.pocoo.org/docs/0.12/) server, running with [Celery](http://docs.celeryproject.org/en/latest/index.html) to handle the distrubuted processing of data and a [RabbitMQ](https://www.rabbitmq.com/) messaging service backing up Celery. The Flask Application is built around a SQLITE3 database.

In the application various open data sources are used to serve the AR Experience. These are compiled into `bundles` by the backend before being sent to the user in one data stream. 

## Data Sources

* [Ramani](ramani.uzuzi.com) to access data from the ESA's sentinel missions, including high res imagery and weather data.
* [FlightAware](http://flightaware.com/) to get historic flight data, including flight paths in order to gather only data appopriate for the flight you're about to take
* [Copernicus App Lab](http://app-lab.eu) Compiles data from multiple soruces, we use that from DBPedia and Open Street Map to get information about cities and landmarks you may encounter on your AR experience.
