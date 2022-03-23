#!/usr/bin/env python3
 
import sys

# Enter three colors separated by spaces. Ignore tolerance 
# c1, c2, c_mult = input('Enter color1 color2 color3: ').split()
colors = sys.argv
assert(len(colors) == 4), 'Must input 3 colors'
c1 = colors[1]
c2 = colors[2]
c_mult = colors[3]

# Mulitples for each color
color_mults = {
    'black' : 1,
    'brown' : 10,
    'red'   : 100,
    'orange': 1000,
    'yellow': 10000,
    'green' : 100000,
    'blue'  : 1000000,
    'purple': 10000000,
    'gray'  : 100000000,
    'grey'  : 100000000,
    'white' : 1000000000,
} 

# Numbers for each color
color_nums = {
    'black' : '0',
    'brown' : '1',
    'red'   : '2',
    'orange': '3',
    'yellow': '4',
    'green' : '5',
    'blue'  : '6',
    'purple': '7',
    'gray'  : '8',
    'grey'  : '8',
    'white' : '9',
}

res = color_nums[c1] + color_nums[c2]   # Append c2 value to the c1; e.g. 1 + 1 = 11
res = int(res) * color_mults[c_mult]    # Convert to int and multiply by multiple
print('%d ohms' % res)                  # Print the result
