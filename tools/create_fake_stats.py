#!/usr/bin/env python3
#
# Copyright (c) 2024 Tomi Leppänen
# Compares svg rendering between QtSvg and librsvg
#
# SPDX-License-Identifier: MIT

import argparse
import datetime
import itertools
import pathlib
import random
import re
import sqlite3
from dataclasses import dataclass

MAX_SCORE = 1000
MIN_SCORE = 200
TIME_SCORE = 800

@dataclass
class Preset:
    type: str
    choices: int
    region: bool
    time: int

    def with_data(self, count, language):
        return PresetWithData(self.type, self.choices, self.region, self.time, count, language)

    def preset(s):
        if s in PRESETS:
            return PRESETS[s]
        else:
            raise ValueError(f"'{s}' is not a preset")

PRESETS = {
    "flags-easy" : Preset("flags", 3, False, 60),
    "flags-regular" : Preset("flags", 4, False, 30),
    "flags-veteran" : Preset("flags", 5, True, 15),
    "maps-easy" : Preset("maps", 3, False, 60),
    "maps-regular" : Preset("maps", 4, True, 30),
    "maps-veteran" : Preset("maps", 5, True, 15),
    "capitals-easy" : Preset("capitals", 3, False, 60),
    "capitals-regular" : Preset("capitals", 4, False, 30),
    "capitals-veteran" : Preset("capitals", 5, True, 15),
}

@dataclass
class PresetWithData(Preset):
    count: str
    language: int

    def into_data(self):
        return [self.type, self.count, self.choices, 'same region' if self.region else 'everywhere', self.time, self.language]

def division(total, pools):
    result = [int(total/pools)] * pools
    missing = total - sum(result)
    for i, j in zip(random.sample(range(pools), k=pools), range(missing)):
        result[i] += 1
    return result

def setup_database(file):
    connection = sqlite3.connect(file)
    cursor = connection.cursor()
    cursor.execute("PRAGMA foreign_keys = ON")
    cursor.execute("CREATE TABLE IF NOT EXISTS options ("
                   "id INTEGER PRIMARY KEY, "
                   "type TEXT, "
                   "questions INTEGER, "
                   "choices INTEGER, "
                   "choices_from TEXT, "
                   "time_to_answer INTEGER, "
                   "language TEXT, "
                   "UNIQUE ( type, questions, choices, choices_from, time_to_answer, language ) ON CONFLICT IGNORE )")
    cursor.execute("CREATE TABLE IF NOT EXISTS records ("
                   "id INTEGER PRIMARY KEY, "
                   "options INTEGER REFERENCES options, "
                   "number_of_correct INTEGER, "
                   "time INTEGER, "
                   "score INTEGER, "
                   "datetime INTEGER, "
                   "name TEXT"
                   ")")
    return connection, cursor

def insert_options(cursor, presets, count, language):
    cursor.executemany("INSERT INTO options ( type, questions, choices, choices_from, time_to_answer, language ) "
                       "VALUES ( ?, ?, ?, ?, ?, ? )", map(lambda x: x.with_data(count, language).into_data(), presets))

def generate_record(preset, name):
    number_of_correct = random.randint(0, preset.count)
    total_time = 0
    score = 0
    for i in range(preset.count):
        time = random.randint(0, preset.time * 1000)
        if i < number_of_correct:
            score += MIN_SCORE + MAX_SCORE * (1.0 - time / (preset.time * TIME_SCORE))
        total_time += time
    end = datetime.datetime.now()
    start = end - datetime.timedelta(days=6*30.44)
    period = end - start
    dt = start + datetime.timedelta(seconds=random.randint(0, int(period.total_seconds())))
    return [number_of_correct, total_time, int(score), int(dt.timestamp()), name]

def generate_records(preset, rows, name):
    for i in range(rows):
        yield generate_record(preset, name)

def insert_records(cursor, preset, rows, name):
    records = generate_records(preset, rows, name)
    cursor.executemany(
        "INSERT INTO records (options, number_of_correct, time, score, datetime, name) "
        "SELECT options.id, ?, ?, ?, ?, ? FROM options "
        "WHERE type = ? AND questions = ? AND choices = ? AND choices_from = ? AND time_to_answer = ? AND language = ?",
        itertools.starmap(lambda a, b: a + b.into_data(), zip(records, itertools.repeat(preset))))

def generate_database(file, rows, presets, count, language, name):
    rows_per_preset = division(rows, len(presets))
    connection, cursor = setup_database(file)
    insert_options(cursor, presets, count, language)
    for preset, rows in zip(presets, rows_per_preset):
        insert_records(cursor, preset.with_data(count, language), rows, name)
    connection.commit()

def language(s):
    if re.match(r"^[a-z]{2}-[A-Z]{2}$", s) is None:
        raise ValueError("'{s}' is not a valid language")
    return s

def count(s):
    value = int(s)
    if value <= 0:
        raise ValueError("'{s}' is not a positive number")
    return value

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('database_file', type=pathlib.Path)
    parser.add_argument('--rows', '-r', type=count, default=1000)
    parser.add_argument('--preset', '-p', type=Preset.preset, action='append', dest='presets')
    parser.add_argument('--count', '-c', type=count, default=15)
    parser.add_argument('--language', '-l', type=language, default='en-GB')
    parser.add_argument('--name', '-n', type=str, default='')
    args = parser.parse_args()
    if not args.presets:
        args.presets = list(PRESETS.values())
    generate_database(args.database_file, args.rows, args.presets, args.count, args.language, args.name)

if __name__ == "__main__":
    main()
