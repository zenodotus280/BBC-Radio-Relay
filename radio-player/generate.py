from jinja2 import Environment, FileSystemLoader
env = Environment(loader=FileSystemLoader('templates'))

import json
with open("stations.json", "r") as d:
        stations = json.load(d)

# --- render index.html
rendered = env.get_template("base.html.j2").render(stations=stations)
fileName = "index.html"
with open(f"./{fileName}", "w") as f:
    f.write(rendered)
# ---

for station in stations:
    rendered = env.get_template("station_base.html.j2").render(stations=stations, station=station)
    html_path = f"./stations/{station['stn_name']}-{station['tz_offset']}.html"
    html_file = open(html_path, 'w')
    html_file.write(rendered)
    html_file.close()
    