#!/usr/bin/env python3
"""Turn global/agents/<name>.md files into the JSON object `claude --agents`
takes, so a headless run gets an agent under its plain name (a plugin would
prefix it).

usage: agent_to_json.py <agent.md>... > agents.json
"""
import json
import re
import sys

agents = {}
for path in sys.argv[1:]:
    _, front, body = open(path).read().split('---', 2)
    meta = dict(re.findall(r'^(\w+): (.*)$', front, re.M))
    agent = {'description': meta['description'], 'prompt': body.strip()}
    for key, field in (('tools', 'tools'), ('disallowedTools', 'disallowedTools')):
        if key in meta:
            agent[field] = [t.strip() for t in meta[key].split(',')]
    if 'model' in meta:
        agent['model'] = meta['model'].strip()
    agents[meta['name']] = agent
json.dump(agents, sys.stdout)
