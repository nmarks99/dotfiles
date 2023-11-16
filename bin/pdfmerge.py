#!/usr/bin/env python3
'''
Merges PDFs

Dependencies:
- pypdf (pip3 install pypdf)

Usage:
pdfmerge file1.pdf file2.pdf --output my_merged_file.pdf # --output or -o
pdfmerge -o my_merged_file.pdf file1.pdf file2.pdf file3.pdf # order not important
'''

from pypdf import PdfWriter
import sys

if len(sys.argv) < 2:
    raise RuntimeError("No input given")

args = sys.argv[1:]
output_name = None
if "-o" or "--output" in args:
    for i, v in enumerate(args):
        if v == "-o" or v == "--output":
            output_name = args[i+1]
            if ".pdf" in output_name:
                output_name = output_name.replace(".pdf","")
            args.pop(i)
            args.pop(i)

if output_name is None:
    output_name = "merged"

merger = PdfWriter()
for file in args:
    merger.append(file)
merger.write("".join([output_name,".pdf"]))
merger.close()
