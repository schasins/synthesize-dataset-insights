import sys
import csv

bitwidth = 12 # later this should be set by user, to make it adjustable
# so Rosette's signed ints can handle from -2**(bitwidth - 1) through 2**(bitwdith - 1 ) - 1
minValueAllowed = (2**(bitwidth - 1)) * -1
maxValueAllowed = (2**(bitwidth - 1)) - 1
rangeAllowed = maxValueAllowed - minValueAllowed

filename = sys.argv[1]
outputfilename = sys.argv[2]

datasetRaw = []
with open(filename, 'rb') as csvfile:
    r = csv.reader(csvfile, delimiter=',', quotechar='"')
    for row in r:
        datasetRaw.append(row)

def isNumeric(s):
    try:
        float(s)
        return 1
    except ValueError:
        return 0

names = datasetRaw[0]
types = []
oldMins = []
oldMaxes = []
newMins = [minValueAllowed] * len(datasetRaw[0])
newMaxes = [maxValueAllowed] * len(datasetRaw[0])

dataset = datasetRaw[1:]

for i in range(len(dataset[0])):
    print i
    values = map(lambda row: row[i], dataset)

    columnType = "categorical"
    uniqueValues = set(values)
    if len(uniqueValues) < 15:
        percentNumeric = 0
        # if we have fewer than 15 values, should treat this as a categorical, rather than search all possible boundaries
        # only consider whether it's numerical if more than 15
    else:
        numNumeric = reduce(lambda acc, val: acc + isNumeric(val), values, 0)
        percentNumeric = float(numNumeric) / (len(dataset) - 1)
    print percentNumeric

    if percentNumeric > .80:
        columnType = "numeric"
        # this should be a numeric row according to current threshold
        dataset = filter(lambda row: isNumeric(row[i]), dataset)
        # since this is numeric, we also need to scale it according to our bitwidth
        numValues = map(lambda row: float(row[i]), dataset)
        oldMax = max(numValues)
        oldMin = min(numValues)
        oldMins.append(oldMin)
        oldMaxes.append(oldMax)
        oldRange = (oldMax - oldMin)
        for j in range(len(dataset)):
            dataset[j][i] =  str((((float(dataset[j][i]) - oldMin) * rangeAllowed) / oldRange) + minValueAllowed)
    else:
        newMins[i] = "NA"
        newMaxes[i] = "NA"
        oldMins.append("NA")
        oldMaxes.append("NA")
    
    values = map(lambda row: row[i], dataset)
    firstItem = values[0]
    allSame = reduce(lambda acc, val: acc and val == firstItem, values, True)
    print allSame
    if allSame:
        columnType = "constant"
    print "****"
    types.append(columnType)

for i in range(len(dataset[0])):
    print i, dataset[0][i], dataset[1][i]

headings = [names, types, oldMins, oldMaxes, newMins, newMaxes]
print "(((((((("
for item in headings:
    print len(item)
print "(((((((("

f = open(outputfilename, "w")
for row in headings + dataset:
    f.write(",".join(map(lambda x: '"'+str(x)+'"', row))+"\n")
f.close()
