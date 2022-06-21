import sys
import glob
import os
from xml.dom import minidom

input_files = glob.glob("C:\\Users\\96176\\Downloads\\MOD SDK\\Mods\\Firestorm\\Data\\Data\\Particles\\*.xml")
new_root = minidom.Element('AssetDeclaration')
for input_file in input_files:
    mydoc = minidom.parse(input_file)

    items = mydoc.getElementsByTagName('AssetDeclaration')

    for item in items:
        for child in item.childNodes:
            new_root.appendChild(child.cloneNode(deep=True))

with open("C:\\Users\\96176\\Desktop\\output.xml", "w") as output_file:
    dom_string = new_root.toprettyxml(newl="")
    output_file.write(dom_string)