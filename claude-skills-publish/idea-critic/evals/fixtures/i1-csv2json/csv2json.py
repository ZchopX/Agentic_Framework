import csv
import json
import sys


def main(argv):
    if len(argv) != 2:
        print("usage: csv2json.py INPUT.csv", file=sys.stderr)
        return 2
    with open(argv[1], newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    json.dump(rows, sys.stdout, ensure_ascii=False, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
