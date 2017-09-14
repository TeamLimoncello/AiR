import requests

api_key = 'd499582d8f88245d34324afa83107671b67cbc33'
base_url = 'https://flightxml.flightaware.com/json/FlightXML3/'
username = 'lewisbell999'

def __get_request__(params, link):
    response = requests.get(base_url+link, params=params, auth=(username, api_key))
    if response.status_code not in range(200,299):
        return 'error: %d' % response.status_code
    return response.json()

def get_flight_history():
    params={
        start_date =''
    }