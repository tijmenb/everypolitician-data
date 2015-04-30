import sys
import json

import vpapi

vpapi.parliament('al/kuvendi')

# Consider only chambers which have a founding date.
chambers = list(vpapi.getall('organizations', where={"classification": "chamber", 'founding_date': {"$exists": True}}))
chambers_by_id = dict(
    [(x['id'], x) for x in chambers]
    )

# I'm not sure what these groups are.
# groups = list(vpapi.getall('organizations', where={"classification": "parliamentary_group"}))

parties = list(vpapi.getall('organizations', where={"classification": "party"}))
people = list(vpapi.getall('people'))
memberships = list(vpapi.getall('memberships'))

chamber_ids = [x['id'] for x in chambers]
# group_ids = [x['id'] for x in groups]
party_ids = [x['id'] for x in parties]
person_ids = [x['id'] for x in people]

# acceptable_orgs = set(chamber_ids)
# acceptable_orgs.update(group_ids, party_ids)

chamber_memberships = [x for x in memberships if x['organization_id'] in chamber_ids]
party_memberships = [x for x in memberships if x['organization_id'] in party_ids]

# From http://stackoverflow.com/questions/2953967/built-in-function-for-computing-overlap-in-python/2953979#2953979
def get_overlap(a, b):
    """a and b are pairs of ints representing intervals.

    Result is the size of the overlap."""
    return max(0, min(a[1], b[1]) - max(a[0], b[0]))

for membership in chamber_memberships:
    my_party_memberships = [x for x in memberships if x['person_id'] == membership['person_id'] and x['organization_id'] in party_ids]

    if len(my_party_memberships) == 1:
        membership['on_behalf_of'] = my_party_memberships[0]['organization_id']
    elif len(my_party_memberships) > 1:
        chamber = chambers_by_id[membership['organization_id']]
        chamber_interval = (int(chamber['founding_date']), int(chamber.get('dissolution_date', sys.maxint)))

        current_party_memberships = [x for x in my_party_memberships if get_overlap(chamber_interval, (int(x.get('start_date', 0)), int(x.get('end_date', sys.maxint))))]

        if len(current_party_memberships) != 1:
            import pdb;pdb.set_trace()
        else:
            membership['on_behalf_of'] = current_party_memberships[0]['organization_id']

    else:
        import pdb;pdb.set_trace()

organizations = parties + chambers

output = {
    'people': people,
    'organizations': organizations,
    'memberships': memberships,
    }

with open('albania/processed.json', 'w') as f:
    json.dump(output, f)

