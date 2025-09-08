#!/usr/bin/env python3
# Copyright (c) 2025 Tomi Leppänen
#
# SPDX-License-Identifier: MIT

import argparse
import math
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pathlib
import scipy
import tqdm
import unicodedata
import yaml

class DataModel:
    def __init__(self, path):
        with open(path) as file:
            self.yaml = yaml.safe_load(file)

    def get(self, index):
        return self.yaml[index]

def clean_string(text):
    s = unicodedata.normalize("NFKD", " ".join(text.strip().split()))
    result = str()
    for c in s:
        category = unicodedata.category(c)
        if not category.startswith("M"):
            result += c
    return result.lower()

# Levenshtein distance algorihm from Wikipedia
# https://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows
def levenshtein(s, t):
    v0 = list(range(0, len(t) + 1))
    v1 = [0 for i in range(len(t) + 1)]

    for i in range(len(s)):
        v1[0] = i + 1
        for j in range(len(t)):
             deletionCost = v0[j + 1] + 1
             insertionCost = v1[j] + 1
             substitutionCost = (v0[j] if s[i] == t[j] else (v0[j] + 1))
             v1[j + 1] = min(deletionCost, insertionCost, substitutionCost)
        v0 = list(v1)
    return v0[len(t)]

def splitted(text, part):
    names = [{"weight": 0, "part": part, "text": text}]
    weight = 1
    for i in range(len(text)):
       if text[i] == ' ' or text[i] == '-':
           s = text[i+1:]
           if s != "":
               names.append({
                   "weight": weight,
                   "part": part,
                   "text": s
               })
               weight += 1
    return names

def build_matchables(item):
    matchables = []
    if "pre" in item:
        matchables.append({
            "weight": 0,
            "part": 0,
            "text": item["pre"] + ' ' + item["name"]
        })
    names = splitted(clean_string(item["name"]), 0)
    matchables.extend(names)
    if "alt" in item:
        names = splitted(clean_string(item["alt"]), 1)
        matchables.extend(names)
    if "other" in item:
        other = item["other"]
        for text in other:
            if text != "":
                names = splitted(clean_string(text), 2)
                matchables.extend(names)
    return matchables

def filter_data(text, data):
    text = clean_string(text)
    mistakes = math.log(len(text), 2) if text else 0
    found = []
    for index, country in enumerate(data):
        matchables = build_matchables(country)
        for item in matchables:
            distance = levenshtein(text, item["text"][:len(text)])
            if distance <= mistakes:
                found.append((item["part"], item["weight"], distance, index))
                break
    found.sort()
    return list(map(lambda x: x[3], found))

def build_data(data, prop):
    df = pd.DataFrame(columns=["country", "letters for first", "letters for only"])
    for index, country in enumerate(tqdm.tqdm(data)):
        letters_for_first = None
        letters_for_only = None
        if prop not in country:
            continue
        text = country[prop]
        for letters in range(1, len(text) + 1):
            filtered = filter_data(text[:letters], data)
            if len(filtered) > 0:
                if letters_for_first is None and filtered[0] == index:
                    letters_for_first = letters
                if letters_for_only is None and len(filtered) == 1:
                    assert filtered[0] == index, f"{filtered[0]} should have been {index}"
                    letters_for_only = letters
        assert prop != "name" or letters_for_first is not None, f"{text} does not have a match"
        assert letters_for_only is None or letters_for_first is not None, f"if only match is found, first match must be too"
        df.loc[index] = [text, letters_for_first, pd.to_numeric(letters_for_only)]
    return df

def data_from_paths(paths, prop):
    dfs = []
    for path in paths:
        with open(path) as file:
            data = yaml.safe_load(file)
        df = build_data(data, prop)
        df["language"] = path.stem[5:]
        dfs.append(df)
    return pd.concat(dfs)

def raw_data(df):
    keys = df.keys()[1:-1]
    index = pd.MultiIndex.from_arrays([df["language"], df["country"]], names=["language", "country"])
    return pd.DataFrame(df[keys].to_numpy(), columns=keys, index=index)

INDICES = ["count", "missing", "mean", "std", "min", "25%", "50%", "75%",
           "max", "mode", "at most 75%", "more than 75%"]

def describe(df):
    data = []
    for language, df_ in df.groupby("language"):
        desc = df_.describe()
        desc.loc["mode"] = [df_[key].mode()[0] for key in desc.keys()]
        desc.loc["at most 75%"] = (df_[desc.keys()] <= df_[desc.keys()].quantile(.75)).sum()
        desc.loc["more than 75%"] = (df_[desc.keys()] > df_[desc.keys()].quantile(.75)).sum()
        desc.loc["missing"] = df_[desc.keys()].isna().sum()
        desc["language"] = language
        data.append(desc.reindex(INDICES))
    data = pd.concat(data)
    keys = data.keys()[:-1]
    index = pd.MultiIndex.from_arrays([data["language"], data.index], names=["language", "variable"])
    return pd.DataFrame(data[keys].to_numpy(), columns=keys, index=index)

def outliers(df):
    outliers = []
    for language, df_ in df.groupby("language"):
        data = []
        for key in df_.keys()[1:-1]:
            data.append(scipy.stats.zscore(df_[key], nan_policy='omit') > 3)
        index = np.stack(data, axis=1).any(axis=1)
        outliers.append(df_[index])
    data = pd.concat(outliers)
    keys = data.keys()[1:-1]
    index = pd.MultiIndex.from_arrays([data["language"], data["country"]], names=["language", "country"])
    return pd.DataFrame(data[keys].to_numpy(), columns=keys, index=index)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_yaml", type=pathlib.Path, nargs='+')
    parser.add_argument("--alt", "-a", action="store_const", const="alt", default="name", dest="prop",
                        help="Use 'alt' text instead of 'name'")
    parser.add_argument("--raw", "-r", action="store_true", default=False, help="Print raw data")
    parser.add_argument("--outliers", "-o", action="store_true", default=False,
                        help="Detect and print outlier candidates")
    args = parser.parse_args()

    df = data_from_paths(args.input_yaml, args.prop)
    with pd.option_context('display.max_rows', None, 'display.max_columns', None):
        if args.raw:
            print(raw_data(df))
            print()
        print("Results")
        print(describe(df))
        if args.outliers:
            print()
            print("Outlier candidates")
            print(outliers(df))

if __name__ == "__main__":
    main()
