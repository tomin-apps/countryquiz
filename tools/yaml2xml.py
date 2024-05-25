#!/usr/bin/env python3
# Copyright (c) 2024 Tomi Leppänen
#
# SPDX-License-Identifier: MIT

import argparse
import pathlib
import yaml
import xml.etree.ElementTree as ET
import xml.dom.minidom as MD

def convert(yaml_path, xml_path):
    with open(yaml_path) as yaml_file, open(xml_path, 'w') as xml_file:
        data = yaml.safe_load(yaml_file)
        root = ET.Element('countries')
        for country in data:
            iso_code = country.pop('iso')
            element = ET.SubElement(root, 'country', { 'iso': iso_code })
            for attr, content in country.items():
                if type(content) == list:
                    for value in content:
                        sub = ET.SubElement(element, attr)
                        sub.text = value
                else:
                    sub = ET.SubElement(element, attr)
                    sub.text = content
        tree = ET.ElementTree(root)
        dom = MD.parseString(ET.tostring(root, 'utf-8', xml_declaration=True))
        dom.writexml(xml_file, addindent='    ', newl='\n', encoding='utf-8')


def convert_languages(yaml_path, xml_path):
    with open(yaml_path) as yaml_file, open(xml_path, 'w') as xml_file:
        data = yaml.safe_load(yaml_file)
        root = ET.Element('languages')
        for language in data:
            attrs = {}
            for attr, content in language.items():
                attrs[attr] = content
            element = ET.SubElement(root, 'language', attrs)
        tree = ET.ElementTree(root)
        dom = MD.parseString(ET.tostring(root, 'utf-8', xml_declaration=True))
        dom.writexml(xml_file, addindent='    ', newl='\n', encoding='utf-8')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--languages', '-l', action='store_const', const=True, default=False)
    parser.add_argument('input_yaml', type=pathlib.Path)
    parser.add_argument('output_xml', type=pathlib.Path)
    args = parser.parse_args()
    if args.languages:
        convert_languages(args.input_yaml, args.output_xml)
    else:
        convert(args.input_yaml, args.output_xml)

if __name__ == "__main__":
    main()
