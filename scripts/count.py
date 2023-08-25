#!/usr/bin/env python

import os
import sys
import csv

# Check if at least one argument is provided
if len(sys.argv) < 2:
    print("Usage: python script.py <filename>")
    sys.exit(1)

# Use the first command-line argument as the filename
fname = sys.argv[1]

try:
    infile = open(fname, 'r')
except FileNotFoundError:
    print(f"File {fname} not found.")
    sys.exit(1)

lines = 0
words = 0
characters = 0
for line in infile:
    line = line.strip(os.linesep)
    wordslist = line.split()
    lines += 1
    words += len(wordslist)
    characters += len(line)

# Close the input file
infile.close()

# Check if summary.csv exists, if not, write headers
if not os.path.exists("summary.csv"):
    with open("summary.csv", "w", newline='') as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(["File Name", "Line Count", "Word Count", "Character Count"])

# Open the summary file in append mode and write data
with open("summary.csv", "a", newline='') as csvfile:
    csvwriter = csv.writer(csvfile)
    csvwriter.writerow([fname, lines, words, characters])

print("Summary written to summary.csv")
