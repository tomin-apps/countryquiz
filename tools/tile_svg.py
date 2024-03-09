#!/usr/bin/env python3

# Copyright (c) 2023-2024 Tomi Leppänen
# Tiles svg image
#
# SPDX-License-Identifier: MIT

import argparse
import cairo
import csv
import concurrent.futures
import gi
import itertools
import os.path
import pathlib
import threading

gi.require_version('Rsvg', '2.0')
from gi.repository import Rsvg

class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

class Dimensions:
    def __init__(self, width, height):
        self.width = int(round(width))
        self.height = int(round(height))

    def scaled(self, scale_factor):
        return Dimensions(float(self.width) * scale_factor, float(self.height) * scale_factor)

class Tile:
    def __init__(self, x, y, left, top, right, bottom):
        self.index = Point(x, y)
        self.topleft = Point(left, top)
        self.dimensions = Dimensions(round(right) - round(left), round(bottom) - round(top))

    def draw(self, surface):
        tile_surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, self.dimensions.width, self.dimensions.height)
        ctx = cairo.Context(tile_surface)
        ctx.set_source_surface(surface, -self.topleft.x, -self.topleft.y)
        ctx.paint()
        return tile_surface

class Surface:
    def __init__(self, svg, scale_factor):
        self.handle = Rsvg.Handle.new_from_file(svg)
        dimensions = self.handle.get_dimensions()
        self.dimensions = Dimensions(dimensions.width, dimensions.height).scaled(scale_factor)
        self.scale_factor = scale_factor

    def paint(self):
        surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, self.dimensions.width, self.dimensions.height)
        ctx = cairo.Context(surface)
        ctx.scale(self.scale_factor, self.scale_factor)
        self.handle.render_cairo(ctx)
        return surface

    def tiled(self, tx, ty):
        tile_width = float(self.dimensions.width) / tx
        tile_height = float(self.dimensions.height) / ty
        top = 0.0
        for y in range(ty):
            left = 0.0
            next_top = top + tile_height
            for x in range(tx):
                next_left = left + tile_width
                yield Tile(x, y, left, top, next_left, next_top)
                left = next_left
            top = next_top

def draw_tile(surface, tile, target_template):
    tile_surface = tile.draw(surface)
    tile_surface.write_to_png(target_template.format(x=tile.index.x, y=tile.index.y))

def tile(filepath, x, y, target, scale_factor):
    surface = Surface(filepath, scale_factor)
    cairo_surface = surface.paint()
    with concurrent.futures.ThreadPoolExecutor() as executor:
        for tile in surface.tiled(x, y):
            executor.submit(draw_tile, cairo_surface, tile, target)

def tiles_from_line(filepath, template, scale, width, height, mtime):
    if not filepath.exists():
        print(f"Input file {filepath} does not exist")
    if mtime < 0 or os.path.getmtime(filepath) > mtime:
        tile(str(filepath), int(width), int(height), str(template), float(scale))

def tiles_from_txt(txt, output_directory):
    output_directory.mkdir(parents=True, exist_ok=True)
    output_txt = output_directory / txt.name[:-3]
    if output_txt.exists():
        mtime = os.path.getmtime(output_txt)
        if os.path.getmtime(txt) > mtime:
            mtime = -1
    else:
        mtime = -1
    csv.register_dialect('custom', delimiter=';', lineterminator='\n', quoting=csv.QUOTE_NONE)
    with open(output_txt, 'w', newline='') as output_file, open(txt, newline='') as input_file:
        writer = csv.writer(output_file, dialect='custom')
        for svg, template, scale, width, height in csv.reader(input_file, dialect='custom'):
            tiles_from_line(txt.parent / svg, output_directory / template, scale, width, height, mtime)
            writer.writerow([template.format(x='%1', y='%2'), scale, width, height])

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('txt', type=pathlib.Path)
    parser.add_argument('--output', '-o', type=pathlib.Path)
    args = parser.parse_args()
    tiles_from_txt(args.txt, args.output)
