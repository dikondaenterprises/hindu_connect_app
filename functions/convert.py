#!/usr/bin/env python3
# convert.py
# Usage: python3 convert.py <sourceScript> <targetScript> <text>
# Performs real‑time transliteration via Aksharamukha library.

import sys
import json
from aksharamukha import transliterate

def main():
    if len(sys.argv) != 4:
        print(json.dumps({"error": "Usage: convert.py <source> <target> <text>"}))
        sys.exit(1)

    source = sys.argv[1]
    target = sys.argv[2]
    text = sys.argv[3]

    try:
        # perform transliteration
        result = transliterate.process(source, target, text)
        # print only the converted text
        print(result)
    except Exception as e:
        # on error, print nothing and exit nonzero
        print(json.dumps({"error": str(e)}))
        sys.exit(2)

if __name__ == "__main__":
    main()
