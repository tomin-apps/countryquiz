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
import sqlite3
from dataclasses import dataclass

LENGTH = 15 # TODO: Allow choices
MAX_SCORE = 1000

@dataclass
class Preset:
    type: str
    count: int
    choices: int
    region: bool
    time: int
    language: str

    def into_data(self):
        return [self.type, self.count, self.choices, 'same region' if self.region else 'everywhere', self.time, self.language]

    def preset(s):
        # TODO: Support selecting length and language
        if s in PRESETS:
            return PRESETS[s]
        else:
            raise ValueError(f"'{s}' is not a preset")

PRESETS = {
    "flags-easy" : Preset("flags", 15, 3, False, 30, 'en'),
    "flags-regular" : Preset("flags", 15, 4, False, 15, 'en'),
    "flags-veteran" : Preset("flags", 15, 5, True, 15, 'en'),
    "maps-easy" : Preset("maps", 15, 3, False, 30, 'en'),
    "maps-regular" : Preset("maps", 15, 4, True, 30, 'en'),
    "maps-veteran" : Preset("maps", 15, 5, True, 15, 'en'),
    "capitals-easy" : Preset("capitals", 15, 3, False, 30, 'en'),
    "capitals-regular" : Preset("capitals", 15, 4, False, 15, 'en'),
    "capitals-veteran" : Preset("capitals", 15, 5, True, 15, 'en'),
}

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

def insert_options(cursor, presets):
    cursor.executemany("INSERT INTO options ( type, questions, choices, choices_from, time_to_answer, language ) "
                       "VALUES ( ?, ?, ?, ?, ?, ? )", map(lambda x: x.into_data(), presets))

def generate_record(preset):
    number_of_correct = random.randint(0, LENGTH)
    total_time = 0
    score = 0
    for i in range(LENGTH):
        time = random.randint(0, preset.time * 1000)
        if i < number_of_correct:
            score += MAX_SCORE * (1.0 - time / (preset.time * 1000))
        total_time += time
    end = datetime.datetime.now()
    start = end - datetime.timedelta(days=6*30.44)
    period = end - start
    dt = start + datetime.timedelta(seconds=random.randint(0, period.total_seconds()))
    return [number_of_correct, total_time, int(score), int(dt.timestamp())]

def generate_records(preset, rows):
    records = []
    for i in range(rows):
        records.append(generate_record(preset))
    return records

def insert_records(cursor, preset, rows):
    records = generate_records(preset, rows)
    cursor.executemany(
        "INSERT INTO records (options, number_of_correct, time, score, datetime, name) "
        "SELECT options.id, ?, ?, ?, ?, '' FROM options "
        "WHERE type = ? AND questions = ? AND choices = ? AND choices_from = ? AND time_to_answer = ? AND language = ?",
        itertools.starmap(lambda a, b: a + b.into_data(), zip(records, itertools.repeat(preset))))

def generate_database(file, rows, presets):
    rows_per_preset = division(rows, len(presets))
    connection, cursor = setup_database(file)
    insert_options(cursor, presets)
    for preset, rows in zip(presets, rows_per_preset):
        insert_records(cursor, preset, rows)
    connection.commit()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('database_file', type=pathlib.Path)
    parser.add_argument('--rows', '-r', type=int, default=1000)
    parser.add_argument('--preset', '-p', type=Preset.preset, action='append', dest='presets')
    args = parser.parse_args()
    if not args.presets:
        args.presets = list(PRESETS.values())
    generate_database(args.database_file, args.rows, args.presets)

if __name__ == "__main__":
    main()
