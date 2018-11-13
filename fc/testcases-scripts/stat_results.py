#!/usr/bin/env python

import re

re_numbers = re.compile("^\\s*(\\d+)\\s+(\\S+)")

count = dict()
with open("results_summary.txt") as f:
    for line in f:
        m = re.match(re_numbers, line)
        if m:
            n = int(m.group(1))
            typ = m.group(2)
            if typ in count:
                count[typ] += n
            else:
                count[typ] = n
for key in sorted(count):
    print("total %-15s: \t%5d" % (key, count[key]))

if "ok" in count and "imprecise" in count:
    total = count["ok"] + count["imprecise"]
    precision = float(count["ok"]) / total
    print("precision (excluding non-terminating): %f" % precision)
