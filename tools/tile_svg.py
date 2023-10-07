#!/usr/bin/env python3

# Copyright (c) 2023 Tomi Leppänen
# Tiles svg image
#
# SPDX-License-Identifier: MIT

import argparse
import cairo
import gi

gi.require_version('Rsvg', '2.0')
from gi.repository import Rsvg

def scale(dimensions, scale_factor):
    return int(dimensions.width * scale_factor), int(dimensions.height * scale_factor)

def paint(svg, scale_factor):
    handle = Rsvg.Handle.new_from_file(svg)
    dimensions = scale(handle.get_dimensions(), scale_factor)
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, *dimensions)
    ctx = cairo.Context(surface)
    ctx.scale(scale_factor, scale_factor)
    handle.render_cairo(ctx)
    return surface

def tiled(width, height, x, y):
    tile_width = float(width) / x
    tile_height = float(height) / y
    top = 0.0
    for i in range(y):
        left = 0.0
        next_top = top + tile_height
        for j in range(x):
            next_left = left + tile_width
            yield (j, i, round(left), round(top), round(next_left) - round(left), round(next_top) - round(top))
            left = next_left
        top = next_top

def draw_tile(surface, left, top, width, height):
    tile_surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, width, height)
    ctx = cairo.Context(tile_surface)
    ctx.set_source_surface(surface, -left, -top)
    ctx.paint()
    return tile_surface

def tile(filepath, x, y, target, scale_factor):
    surface = paint(filepath, scale_factor)
    for tile in tiled(surface.get_width(), surface.get_height(), x, y):
        tile_surface = draw_tile(surface, *tile[2:])
        tile_surface.write_to_png(target.format(x=tile[0], y=tile[1]))

def target(text):
    if "{x}" not in text:
        raise ValueError("{} does not contain '{x}'".format(text))
    if "{y}" not in text:
        raise ValueError("{} does not contain '{y}'".format(text))
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
