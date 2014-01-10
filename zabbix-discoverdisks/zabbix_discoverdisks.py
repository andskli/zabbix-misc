#!/usr/bin/env python
#
# Forced to use ugly/dumb json formatting due to the lack of newer
# python version and/or python json module.
#
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
