f = open('data.txt', 'r')
out = open('formatted.txt', 'w')

for line in f:
    line = line[9:-3]
    splitLine = [line[i:i+8] for i in range(0, len(line), 8)]
    out.write(' '.join(splitLine) + '\n')
