import math

# Ellipsoid model constants (actual values here are for WGS84)
sm_a = 6378137.0
sm_b = 6378301.898519918


def lat_long_to_wgs84(lat, long, isDeg=True):
    """
    lat_long_to_wgs84

     Converts a latitude/longitude pair to x and y coordinates in the
     World Mercator projection.

     Inputs:
       lat   - Latitude of the point.
       long  - Longitude of the point.
       isDeg - Whether the given latitude and longitude are in degrees. If True
               (default) it is assumed they are in radians.

     Returns:
       x,y - A 2-element tuple with the World Mercator x and y values.

    """
    long0 = 0
    if isDeg:
        lat = deg_to_rad(lat)
        long = deg_to_rad(long)

    x = sm_a * (long - long0)
    y = sm_b * math.log((1 + math.sin(lat)) / (1 - math.sin(lat))) / 2

    return x, y


def wgs84_to_lat_long(x, y, deg=True):
    long0 = 0
    long = x / sm_a + long0
    lat = math.asin((math.exp(2 * y / sm_b) - 1) / (math.exp(2 * y / sm_b) + 1))

    if deg:
        lat = rad_to_deg(lat)
        long = rad_to_deg(long)
    return lat, long


def deg_to_rad(deg):
    return deg / 180.0 * math.pi


def rad_to_deg(rad):
    return rad / math.pi * 180.0
