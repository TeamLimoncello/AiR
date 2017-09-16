import math
from urllib.request import urlopen

from PIL import Image

import mercator as merc

ramani_factor = 1.1943285667419434*256*16


def frange(a,b,step=1.0):
    while a < b:
        yield a
        a += step


def generate_points(path):
    # path :: [(time, lat, long, alt)]
    points = set()
    for pos in path.rstrip().split('\n'):
        time, lat, long, alt = parse_csv_line(pos)
        x_pos, y_pos = merc.lat_long_to_wgs84(lat, long)
        x_pos /= ramani_factor
        y_pos /= ramani_factor

        def floor_to_half(n):
            return 0.5 + math.floor(n - 0.5)

        def ceil_to_half(n):
            return 0.5 + math.ceil(n - 0.5)

        distance_sq = 6**2
        min_y = floor_to_half(y_pos-6)
        max_y = ceil_to_half(y_pos+6)
        min_x = floor_to_half(x_pos - 6)
        max_x = ceil_to_half(x_pos + 6)
        points.update((x, y) for x in frange(min_x, max_x+1)
                             for y in frange(min_y, max_y+1)
                             if (x-x_pos)**2 + (y-y_pos)**2 <= distance_sq)

    points = list(points)
    points.sort(key=lambda pair: tuple(reversed(pair)))
    return points


def get_bounding_box(x,y):
    return "{},{},{},{}".format(
        (x-0.5)*ramani_factor,
        (y-0.5)*ramani_factor,
        (x+0.5)*ramani_factor,
        (y+0.5)*ramani_factor,
    )


def parse_csv_line(line):
    row = line.split(',')
    return int(row[0]), float(row[1]), float(row[2]), int(row[3])


# sorted_points: [xmin, xmax, y]
def group_points(sorted_points):
    if not sorted_points: return []
    grouped = [[sorted_points[0][0], sorted_points[0][0], sorted_points[0][1]]]
    for x,y in sorted_points[1:]:
        if grouped[-1][1] == x-1 and grouped[-1][2] == y:
            grouped[-1][1] = x
        else:
            grouped.append([x, x, y])
    return grouped


def image_url(bounding_box):
    return ('https://ramani.ujuizi.com/cloud/wms/ramaniddl/tilecache?'
            'SERVICE=WMS&REQUEST=GetMap&VERSION=1.1.1&'
            'LAYERS=ddl.s2cloudless3857&MAXCC=20&'
            'TOKEN=672c11ca84f44027acf77ff79871607e&'
            'PACKAGE=it.airexperience.air&BBOX={}').format(bounding_box)


def mercator_bounds(group):
    x0, x1, y = group
    alat, along = merc.wgs84_to_lat_long((x0-0.5)*ramani_factor, (y-0.5)*ramani_factor)
    blat, blong = merc.wgs84_to_lat_long((x1+0.5)*ramani_factor, (y+0.5)*ramani_factor)
    return alat, along, blat, blong


def fetch_group_image(group):
    x0, x1, y = group
    result = Image.new('RGB', (256, 256*(x1+1-x0)))
    for i, x in enumerate(frange(x0, x1+1)):
        image = Image.open(urlopen(image_url(get_bounding_box(x,y))))
        result.paste(image, (256*i, 0))
    return result
