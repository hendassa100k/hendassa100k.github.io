#!/usr/bin/env python3

import os
import sys
import glob
import yaml
import pathlib
import datetime

POSTS_GLOB = "src/posts/*.md"
BASE_URL = os.getenv("BASE_URL")
TITLE = os.getenv("TITLE")

required = ["BASE_URL", "TITLE"]
missing = [name for name in required if not os.getenv(name)]

if missing:
    for name in missing:
        sys.stderr.write(f"Error: environment variable {name} is not set\n")
    sys.exit(1)

BASE_URL = os.getenv("BASE_URL")
TITLE = os.getenv("TITLE")

def load_front_matter(md_path: pathlib.Path) -> dict:
    with md_path.open("r", encoding="utf-8") as f:
        lines = f.readlines()

    if not (lines[0].strip() == "---"):
        raise ValueError(f"{md_path} doesn't begins with '---'")

    try:
        end_idx = lines[1:].index("---\n") + 1
    except ValueError:
        raise ValueError(f"Closing '---' not found in {md_path}")

    yaml_block = "".join(lines[1:end_idx])
    return yaml.safe_load(yaml_block)


def build_post_entry(md_path: pathlib.Path, fm: dict) -> dict:
    file_stem = md_path.stem
    return {
        "title": fm.get("title", ""),
        "date": fm.get("date", fm.get("date", "")),
        "url": f"{BASE_URL}/posts/{file_stem}",
        "path": f"posts/{file_stem}",
        "abstract": fm.get("abstract", "").strip(),
    }


def main() -> None:
    posts = []

    for md_file in glob.glob(POSTS_GLOB):
        md_path = pathlib.Path(md_file)
        try:
            fm = load_front_matter(md_path)
        except Exception as e:
            sys.stderr.write(f"Skipping {md_path}: {e}\n")
            continue

        entry = build_post_entry(md_path, fm)
        posts.append(entry)

    output_data = {
        "title": TITLE,
        "url": BASE_URL,
        "date": datetime.datetime.combine(datetime.datetime.now(datetime.UTC), datetime.time.min).isoformat(),
        "posts": posts,
    }

    # yaml.safe_dump(output_data, sys.stdout, sort_keys=False, allow_unicode=True)

    if (len(sys.argv) < 1):
        sys.stderr.write("Error: output file is not specified\n")
        sys.exit(1)

    out_path = sys.argv[1]
    with open(out_path, "w", encoding="utf-8") as f:
        yaml.safe_dump(output_data, f, sort_keys=False, allow_unicode=True)

if __name__ == "__main__":
    main()
