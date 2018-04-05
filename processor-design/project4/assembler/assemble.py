#! /usr/bin/env python

# Benjamin Newcomer & Casey Evanish
# CS 3220 Project 2

# This file is a script that runs the assembler


import sys, argparse
from assembler import Assembler

parser = argparse.ArgumentParser(description='Assemble some assembly!')

# add args
parser.add_argument('file', 
	help='the file to assemble')
parser.add_argument('output',
	help='the filename to give to the output')

#parse args
args = parser.parse_args()
assembler = Assembler(args)
assembler.assemble()
