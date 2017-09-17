import math
from urllib.request import urlopen

from PIL import Image

import mercator as merc

ramani_factor = 1.1943285667419434*256

def frange(a,b,step=1.0):
    while a < b:
        yield a
        a += step


class Tiler:

    def __init__(self, zoom=16, radius=6, params='LAYERS=ddl.s2cloudless3857&MAXCC=20'):
        self.zoom = zoom
        self.radius = radius
        self.params = params

    def serialize(self):
        return self.zoom, self.radius, self.params

    def generate_points(self, path):
        # path :: [(time, lat, long, alt)]
        points = set()
        for pos in path.rstrip().split('\n'):
            time, lat, long, alt = parse_csv_line(pos)
            x_pos, y_pos = merc.lat_long_to_wgs84(lat, long)
            x_pos /= ramani_factor * self.zoom
            y_pos /= ramani_factor * self.zoom

            def floor_to_half(n):
                return 0.5 + math.floor(n - 0.5)

            def ceil_to_half(n):
                return 0.5 + math.ceil(n - 0.5)

            distance_sq = self.radius**2
            min_y = floor_to_half(y_pos - self.radius)
            max_y = ceil_to_half(y_pos + self.radius)
            min_x = floor_to_half(x_pos - self.radius)
            max_x = ceil_to_half(x_pos + self.radius)
            points.update((x, y) for x in frange(min_x, max_x+1)
                                 for y in frange(min_y, max_y+1)
                                 if (x-x_pos)**2 + (y-y_pos)**2 <= distance_sq)
        return points

    def get_bounding_box(self, x, y):
        return "{},{},{},{}".format(
            (x-0.5) * ramani_factor * self.zoom,
            (y-0.5) * ramani_factor * self.zoom,
            (x+0.5) * ramani_factor * self.zoom,
            (y+0.5) * ramani_factor * self.zoom,
        )

    def mercator_bounds(self, group):
        x0, x1, y = group
        alat, along = merc.wgs84_to_lat_long(
            (x0-0.5) * ramani_factor * self.zoom,
            (y-0.5) * ramani_factor * self.zoom)
        blat, blong = merc.wgs84_to_lat_long(
            (x1+0.5) * ramani_factor * self.zoom,
            (y+0.5) * ramani_factor * self.zoom)
        return alat, along, blat, blong

    def fetch_group_image(self, group):
        x0, x1, y = group
        result = Image.new('RGB', (256*int(x1-x0), 256))
        for i, x in enumerate(frange(x0, x1)):
            try:
                image = Image.open(urlopen(self.image_url(self.get_bounding_box(x, y))))
                result.paste(image, (256*i, 0))
            except OSError as e:
                print(self.image_url(self.get_bounding_box(x, y)))
                print(e)
        return result

    def zoom_by(self, factor, points):
        self.zoom /= factor
        self.radius *= factor
        return [(x, y) for point in points
                for x in frange((point[0] - 0.5) * factor + 0.5, (point[0] + 0.5) * factor)
                for y in frange((point[1] - 0.5) * factor + 0.5, (point[1] + 0.5) * factor)]

    def image_url(self, bounding_box):
        return ('https://ramani.ujuizi.com/cloud/wms/ramaniddl/tilecache?'
                'SERVICE=WMS&REQUEST=GetMap&VERSION=1.1.1&{}&'
                'TOKEN=672c11ca84f44027acf77ff79871607e&'
                'PACKAGE=it.airexperience.air&BBOX={}').format(
            self.params, bounding_box)


def parse_csv_line(line):
    row = line.split(',')
    return int(row[0]), float(row[1]), float(row[2]), int(row[3])


def sort_points(points):
    return sorted(points, key=lambda pair: tuple(reversed(pair)))


# grouped : [xmin, xmax+1, y]
def group_points(points):
    if not points: return []
    sorted_points = sort_points(points)
    grouped = [[sorted_points[0][0], sorted_points[0][0], sorted_points[0][1]]]
    for x,y in sorted_points[1:]:
        if grouped[-1][1] == x and grouped[-1][2] == y:
            grouped[-1][1] += 1
        else:
            grouped.append([x, x+1, y])
    return grouped
