#!/usr/bin/env python
# Forced to use ugly/dumb json formatting
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#

fh = open("/proc/diskstats","r")

disklist = []
for l in fh:
   l = l.split()
   disklist.append(l[2])

print "{"
print "\t\"data\":["
while disklist:
   print "\t{"
   print "\t\t\"{#DISKNAME}\":\"%s\"" % disklist.pop()
   if len(disklist) > 0:
      print "\t},"
   else:
      print "\t}"

print "\t]"
print "}"

fh.close()
