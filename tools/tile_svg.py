#!/usr/bin/env python3

# Copyright (c) 2023-2024 Tomi Leppänen
# Tiles svg image
#
# SPDX-License-Identifier: MIT

import argparse
import cairo
import concurrent.futures
import gi
import itertools
import os.path
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
        self.svg = svg
        self.handle = Rsvg.Handle.new_from_file(svg)
        dimensions = self.handle.get_dimensions()
        self.dimensions = Dimensions(dimensions.width, dimensions.height).scaled(scale_factor)
        self.scale_factor = scale_factor

    def check_tiles(self, x, y, target_template):
        surface_mtime = os.path.getmtime(self.svg)
        for tile in self.tiled(x, y):
            path = target_template.format(x=tile.index.x, y=tile.index.y)
            if not os.path.isfile(path) or os.path.getmtime(path) < surface_mtime:
                return True
        return False

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
    if surface.check_tiles(x, y, target):
        cairo_surface = surface.paint()
        with concurrent.futures.ThreadPoolExecutor() as executor:
            for tile in surface.tiled(x, y):
                executor.submit(draw_tile, cairo_surface, tile, target)

def target(text):
    if "{x}" not in text:
        raise ValueError("{} does not contain '{{x}}'".format(text))
    if "{y}" not in text:
        raise ValueError("{} does not contain '{{y}}'".format(text))
    return text

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('svg')
    parser.add_argument('x', type=int)
    parser.add_argument('y', type=int)
    parser.add_argument('target', type=target)
    parser.add_argument('--scale-factor', '-s', type=float, default=1.0)
    args = parser.parse_args()
    tile(args.svg, args.x, args.y, args.target, args.scale_factor)
