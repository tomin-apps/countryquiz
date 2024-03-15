#!/usr/bin/env python3
#
# Copyright (c) 2024 Tomi Leppänen
# Compares svg rendering between QtSvg and librsvg
#
# SPDX-License-Identifier: MIT

import argparse
import cairo
import gi
import pathlib
import PySide2.QtGui
import PySide2.QtSvg

gi.require_version('Rsvg', '2.0')
from gi.repository import Rsvg

def draw_with_librsvg(file):
    handle = Rsvg.Handle.new_from_file(file)
    dimensions = handle.get_dimensions()
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, dimensions.width, dimensions.height)
    ctx = cairo.Context(surface)
    handle.render_cairo(ctx)
    return surface

def draw_with_qtsvg(file):
    renderer = PySide2.QtSvg.QSvgRenderer(file)
    dimensions = renderer.defaultSize()
    image = PySide2.QtGui.QImage(dimensions, PySide2.QtGui.QImage.Format.Format_ARGB32_Premultiplied)
    painter = PySide2.QtGui.QPainter(image)
    renderer.render(painter)
    return image

def position(size):
    for y in range(size.height()):
        for x in range(size.width()):
            yield PySide2.QtCore.QPoint(x, y)

def compare(file, output_file, skip_same):
    surface = draw_with_librsvg(file)
    image = draw_with_qtsvg(file)
    size = image.size()
    size.setWidth(size.width() * 4)
    result = PySide2.QtGui.QImage(size, PySide2.QtGui.QImage.Format.Format_Indexed8)
    result.setColor(0, PySide2.QtGui.QColor(PySide2.QtCore.Qt.GlobalColor.black).rgb())
    result.setColor(1, PySide2.QtGui.QColor(PySide2.QtCore.Qt.GlobalColor.white).rgb())
    different = False
    for p, a, b in zip(position(size), surface.get_data(), image.bits()):
        if a == b:
            result.setPixel(p, 0)
        else:
            result.setPixel(p, 1)
            different = True

    if not skip_same or different:
        result.save(output_file)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('svg_file', type=pathlib.Path)
    parser.add_argument('--output', '-o', type=pathlib.Path)
    parser.add_argument('--skip-same', '-s', action='store_true', default=False)
    args = parser.parse_args()
    compare(str(args.svg_file),
            str(args.output) if args.output is not None else str(args.svg_file) + ".compare.png",
            args.skip_same)

if __name__ == "__main__":
    main()
