import sys
import os
import json

import vpapi

endpoints = [ 'people', 'organizations', 'memberships', 'posts', 'areas', 'events' ]

vpapi.parliament(sys.argv[1])

output = {}
for endpoint in endpoints:
    output[endpoint] = list(vpapi.getall(endpoint))

print json.dumps(output, indent=4, sort_keys=True)
