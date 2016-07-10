#!/usr/bin/env python2
# Pierre-Olivier Vauboin <povauboin@gmail.com>
# LuaStrip - Replace lua constants in an attempt to save tx memory

import re
import sys

local = re.compile('^local ([A-Z0-9_]+) = (.*[A-Z0-9]+.*)')
lookup = {}

if not len(sys.argv) == 3:
    print 'usage: %s infile outfile' % sys.argv[0]
    sys.exit(1)

with open(sys.argv[1]) as f:
    with open(sys.argv[2], 'w') as o:
        for line in f:
            line = line.strip('\n')
            # Do substitutions
            for symbol,value in lookup.iteritems():
                if symbol in line:
                    line = line.replace(symbol, '(%s)' % value)

            # Record symbol value
            m = local.match(line)
            if m:
                i = m.group(2).find(' --')
                lookup[m.group(1)] = m.group(2)[:i if i != -1 else None]
                # Delete line
            else:
                # Keep line
                o.write('%s\n' % line)
