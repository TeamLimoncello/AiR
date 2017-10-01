import json
import re


def main():
    """
        Convert the OSM-formatted JSON file `cities.json` into AiR-specific `parsed-ctiies.json`, discarding invalid
        data and parsing populations.
    """
    json_data = json.loads(open('cities.json').read())
    open('cities.json').close()
    results=[]
    for i in json_data['elements']:
        if 'population' in i['tags']:
            population = i['tags']['population'] if all(ord(c) < 128 for c in i['tags']['population']) else ''
            try:
                population = re.sub(r'\(.*\)', '', population)
                population = int(re.sub(r'\D', '', re.sub(r';.*$', '', population)))
            except ValueError:
                population = None
        else:
            population = None
        results.append({
            'name': i['tags']['name'] if 'name' in i['tags'] else None,
            'lat': i['lat'],
            'long': i['lon'],
            'population': population,
            'name_en': i['tags']['name:en'] if 'name:en' in i['tags'] else None
        })
    result_file = open('parsed_cities.json', 'w+')
    result_file.write(json.dumps(results))


if __name__ == '__main__':
    main()