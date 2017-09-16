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
    csv_path = map(lambda row: row.split(','), path.split('\n'))
    for pos in csv_path:
        x_pos,y_pos = merc.lat_long_to_wgs84(pos[1], pos[2])
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


def get_bounding_box(point):
    x, y = point
    return "{},{},{},{}".format(
        (x-0.5)*ramani_factor,
        (y-0.5)*ramani_factor,
        (x+0.5)*ramani_factor,
        (y+0.5)*ramani_factor,
    )


def parse_csv_line(line):
    row = line.split(',')
    return int(row[0]), float(row[1]), float(row[2]), int(row[3])


def group_points(sorted_points):
    if not sorted_points: return []
    grouped = [(sorted_points[0][0],[sorted_points[0][1]])]
    for x,y in sorted_points[1:]:
        if grouped[-1] == (x,y-1):
            grouped[-1][1].append(y)
        else:
            grouped.append((x, [y]))
    return grouped


def image_url(bounding_box):
    return ('https://ramani.ujuizi.com/cloud/wms/ramaniddl/tilecache?'
            'SERVICE=WMS&REQUEST=GetMap&VERSION=1.1.1&'
            'LAYERS=ddl.s2cloudless3857&MAXCC=20&'
            'TOKEN=672c11ca84f44027acf77ff79871607e&'
            'PACKAGE=it.airexperience.air&BBOX={}').format(bounding_box)


def mercator_bounds(group):
    x, ys = group
    alat, along = merc.wgs84_to_lat_long((x-0.5)*ramani_factor, (ys[0]-0.5)*ramani_factor)
    blat, blong = merc.wgs84_to_lat_long((x+0.5)*ramani_factor, (ys[-1]+0.5)*ramani_factor)
    return alat, along, blat, blong


def fetch_group_image(group):
    x, ys = group
    images = []
    result = Image.new('RGB', (256, 256*len(ys)))
    for i, y in enumerate(ys):
        image = Image.open(urlopen(image_url(get_bounding_box(y))))
        result.paste(image, (0, 256*y))
    return result


if __name__ == '__main__':
    string = ('0,51.4776000977,-0.483319997787,11\n'
              '174,51.4557685852,-0.758360028267,84\n'
              '315,51.3359489441,-0.944060027599,112\n'
              '495,51.0897216797,-1.20441305637,160\n'
              '670,50.8585090637,-1.52107000351,210\n'
              '807,50.6448287964,-1.74334001541,241\n'
              '927,50.4326515198,-1.93423998356,264\n'
              '1085,50.1309394836,-2.18553996086,292\n'
              '1237,49.8394813538,-2.4026799202,321\n'
              '1389,49.5317687988,-2.62862992287,348\n'
              '1543,49.2387695312,-2.84083008766,350\n'
              '1697,48.9409790039,-3.05363988876,350\n'
              '1851,48.6418304443,-3.26460003853,350\n'
              '2013,48.3241615295,-3.48576998711,350\n'
              '2164,48.0333900452,-3.68548989296,350\n'
              '2297,47.7719116211,-3.86302995682,350\n'
              '2448,47.4790916443,-4.05958986282,350\n'
              '2607,47.1694297791,-4.26468992233,350\n'
              '2728,46.9379882812,-4.41629981995,353\n'
              '2881,46.6372413635,-4.61110019684,370\n'
              '3045,46.3213310242,-4.81322002411,370\n'
              '3166,46.0862312317,-4.96192979813,370\n'
              '3287,45.859588623,-5.10404014587,370\n'
              '3456,45.5313491821,-5.30767011642,370\n'
              '3607,45.2376289368,-5.48766994476,370\n'
              '3759,44.9474487305,-5.66371011734,370\n'
              '3910,44.6553688049,-5.83823013306,370\n'
              '4082,44.3126602173,-6.0110001564,370\n'
              '4234,44.0077896118,-6.16247987747,370\n'
              '4389,43.6988487244,-6.31426000595,370\n'
              '4539,43.3955802917,-6.46173000336,370\n'
              '4690,43.0925216675,-6.60774993896,370\n'
              '4811,42.8498916626,-6.72356987,370\n'
              '4972,42.5229492188,-6.87812995911,370\n'
              '5093,42.2833099365,-6.99036312103,370\n'
              '5234,42.0081291199,-7.14437007904,371\n'
              '5355,41.7815589905,-7.30852985382,370\n'
              '5484,41.5452613831,-7.47863006592,370\n'
              '5605,41.3202781677,-7.6393699646,370\n'
              '5756,41.041809082,-7.83655023575,370\n'
              '5877,40.8183097839,-7.99337005615,370\n'
              '6028,40.5379714966,-8.18836975098,370\n'
              '6180,40.2525291443,-8.38488960266,335\n'
              '6360,39.9244499207,-8.62427043915,272\n'
              '6519,39.6648788452,-8.83777046204,231\n'
              '6699,39.4111709595,-9.04467964172,203\n'
              '6879,39.164150238,-9.21728992462,164\n'
              '7030,38.9574317932,-9.32172012329,129\n'
              '7199,38.7300605774,-9.40567016602,89\n'
              '7372,38.5494689941,-9.32028961182,61\n'
              '7542,38.6525611877,-9.2047700882,25\n'
              '7683,38.7374687195,-9.15942001343,9\n')
    boxes = map(get_bounding_box, generate_points(map(parse_csv_line, string.rstrip().split('\n'))))
    for box in boxes:
        print("<img src='https://ramani.ujuizi.com/cloud/wms/ramaniddl/tilecache?SERVICE=WMS&REQUEST=GetMap&VERSION=1.1.1&LAYERS=ddl.s2cloudless3857&MAXCC=20&SRS=EPSG%3A3857&ZINDEX=400&REUSETILES=true&COLCOR=SenCor%2CBOOST&TOKEN=672c11ca84f44027acf77ff79871607e&PACKAGE=it.airexperience.air&BBOX={}'>".format(box))
