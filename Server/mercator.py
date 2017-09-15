import math

# Ellipsoid model constants (actual values here are for WGS84)
sm_a = 6378137.0
sm_b = 6356752.314


def projLatLonToWorldMercator(lat, lon, isDeg=True):
    """
    LatLonToWorldMercator

     Converts a latitude/longitude pair to x and y coordinates in the
     World Mercator projection.

     Inputs:
       lat   - Latitude of the point.
       lon   - Longitude of the point.
       isDeg - Whether the given latitude and longitude are in degrees. If False
               (default) it is assumed they are in radians.

     Returns:
       x,y - A 2-element tuple with the World Mercator x and y values.

    """
    lon0 = 0
    if isDeg:
        lat = projDegToRad(lat)
        lon = projDegToRad(lon)

    x = sm_a * (lon - lon0)
    y = sm_a * math.log((math.sin(lat) + 1) / math.cos(lat))

    return x, y


def projDegToRad(deg):
    return (deg / 180.0 * math.pi)


def projRadToDeg(rad):
    return (rad / math.pi * 180.0)
