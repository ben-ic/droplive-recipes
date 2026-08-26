#!/usr/bin/env python3
"""Generate LIVE_NOW.md from the public DropLive catalogue."""

from __future__ import annotations

import json
import os
from html import escape
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.parse import urljoin, urlsplit
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "LIVE_NOW.md"
CATALOG_URL = "https://droplive.io/projects?sort=name"
MAX_RESPONSE_BYTES = 5 * 1024 * 1024


def classes(attributes: dict[str, str | None]) -> set[str]:
    return set((attributes.get("class") or "").split())


def clean_text(parts: list[str]) -> str:
    return " ".join("".join(parts).split())


class CatalogParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.jsonld_scripts: list[str] = []
        self.cards: list[dict[str, Any]] = []
        self._jsonld_parts: list[str] | None = None
        self._card: dict[str, Any] | None = None
        self._card_depth = 0
        self._captures: list[tuple[str, int]] = []

    def handle_starttag(
        self, tag: str, raw_attributes: list[tuple[str, str | None]]
    ) -> None:
        attributes = dict(raw_attributes)
        tag_classes = classes(attributes)

        if tag == "script" and attributes.get("type") == "application/ld+json":
            self._jsonld_parts = []

        if self._card is None:
            if tag == "a" and "app-card" in tag_classes:
                self._card = {
                    "href": attributes.get("href"),
                    "name_parts": [],
                    "description_parts": [],
                    "has_data": False,
                }
                self._card_depth = 1
            return

        self._card_depth += 1

        if "title" in tag_classes:
            self._captures.append(("name_parts", self._card_depth))
        elif "subtitle" in tag_classes:
            self._captures.append(("description_parts", self._card_depth))

        if {"pill", "data"}.issubset(tag_classes):
            self._card["has_data"] = True

    def handle_data(self, data: str) -> None:
        if self._jsonld_parts is not None:
            self._jsonld_parts.append(data)

        if self._card is not None and self._captures:
            field, _depth = self._captures[-1]
            self._card[field].append(data)

    def handle_endtag(self, tag: str) -> None:
        if tag == "script" and self._jsonld_parts is not None:
            self.jsonld_scripts.append("".join(self._jsonld_parts))
            self._jsonld_parts = None

        if self._card is None:
            return

        while self._captures and self._captures[-1][1] == self._card_depth:
            self._captures.pop()

        self._card_depth -= 1
        if self._card_depth != 0:
            return

        self.cards.append(
            {
                "href": self._card["href"],
                "name": clean_text(self._card["name_parts"]),
                "description": clean_text(self._card["description_parts"]),
                "has_data": self._card["has_data"],
            }
        )
        self._card = None


def fetch_catalog() -> str:
    request = Request(
        CATALOG_URL,
        headers={
            "Accept": "text/html",
            "User-Agent": "droplive-recipes-live-list/1.0",
        },
    )

    with urlopen(request, timeout=30) as response:
        final_url = urlsplit(response.geturl())
        if (
            response.status != 200
            or final_url.scheme != "https"
            or final_url.netloc != "droplive.io"
            or final_url.path != "/projects"
        ):
            raise RuntimeError(
                f"unexpected catalogue response: {response.status} {response.geturl()}"
            )

        body = response.read(MAX_RESPONSE_BYTES + 1)
        if len(body) > MAX_RESPONSE_BYTES:
            raise RuntimeError("catalogue response is larger than 5 MiB")

        charset = response.headers.get_content_charset() or "utf-8"
        return body.decode(charset)


def item_list(scripts: list[str]) -> tuple[list[dict[str, str]], int]:
    for script in scripts:
        try:
            value = json.loads(script)
        except json.JSONDecodeError:
            continue

        if not isinstance(value, dict) or value.get("@type") != "ItemList":
            continue

        raw_items = value.get("itemListElement")
        count = value.get("numberOfItems")
        if not isinstance(raw_items, list) or not isinstance(count, int):
            raise RuntimeError("catalogue ItemList is missing its items or count")
        if count != len(raw_items):
            raise RuntimeError(
                f"catalogue ItemList count is {count}, but it contains {len(raw_items)} items"
            )

        items: list[dict[str, str]] = []
        for raw_item in raw_items:
            if not isinstance(raw_item, dict):
                raise RuntimeError("catalogue ItemList contains an invalid item")

            name = raw_item.get("name")
            url = raw_item.get("url")
            if not isinstance(name, str) or not name.strip() or not isinstance(url, str):
                raise RuntimeError("catalogue ItemList contains an item without a name or URL")

            absolute_url = urljoin(CATALOG_URL, url)
            parsed_url = urlsplit(absolute_url)
            if (
                parsed_url.scheme != "https"
                or parsed_url.netloc != "droplive.io"
                or not parsed_url.path.startswith("/projects/")
                or parsed_url.query
                or parsed_url.fragment
            ):
                raise RuntimeError(f"unsafe project URL in catalogue: {absolute_url}")

            items.append({"name": name.strip(), "url": absolute_url})

        return items, count

    raise RuntimeError("catalogue does not contain an ItemList JSON-LD document")


def read_catalog(html: str) -> list[dict[str, Any]]:
    parser = CatalogParser()
    parser.feed(html)
    parser.close()

    items, expected_count = item_list(parser.jsonld_scripts)
    item_urls = [item["url"] for item in items]
    if len(set(item_urls)) != expected_count:
        raise RuntimeError("catalogue ItemList contains duplicate project URLs")

    cards: dict[str, dict[str, Any]] = {}
    for card in parser.cards:
        href = card.get("href")
        if not isinstance(href, str):
            raise RuntimeError("catalogue contains a project card without a URL")

        url = urljoin(CATALOG_URL, href)
        if url in cards:
            raise RuntimeError(f"catalogue contains a duplicate project card: {url}")
        cards[url] = card

    if set(cards) != set(item_urls):
        missing = sorted(set(item_urls) - set(cards))
        extra = sorted(set(cards) - set(item_urls))
        raise RuntimeError(
            "catalogue cards do not match ItemList URLs; "
            f"missing={missing!r}, extra={extra!r}"
        )

    rows: list[dict[str, Any]] = []
    for item in items:
        card = cards[item["url"]]
        if card["name"] != item["name"]:
            raise RuntimeError(
                f"catalogue name mismatch for {item['url']}: "
                f"{item['name']!r} != {card['name']!r}"
            )
        if not card["description"]:
            raise RuntimeError(f"catalogue card has no description: {item['url']}")

        rows.append({**item, **card})

    if len(rows) != expected_count:
        raise RuntimeError(
            f"catalogue expected {expected_count} projects, but parsed {len(rows)}"
        )

    return rows


def table_text(value: str) -> str:
    return escape(" ".join(value.split()), quote=False).replace("|", "\\|")


def render(rows: list[dict[str, Any]]) -> str:
    with_data = sum(1 for row in rows if row["has_data"])
    lines = [
        "# Live now",
        "",
        f"{len(rows)} projects have a current public DropLive demo. "
        f"{with_data} include sample data.",
        "",
        "This file is generated each day from the "
        f"[public DropLive catalogue]({CATALOG_URL}). "
        "Do not edit it by hand.",
        "",
        "| Project | What it does | Sample data | Try it |",
        "| --- | --- | :---: | --- |",
    ]

    for row in rows:
        sample_data = "Yes" if row["has_data"] else "—"
        slug = urlsplit(row["url"]).path.rsplit("/", 1)[-1]
        lines.append(
            f"| {table_text(row['name'])} "
            f"| {table_text(row['description'])} "
            f"| {sample_data} "
            f"| [![Try with DropLive](https://droplive.io/badge/{slug}.svg)]"
            f"({row['url']}) |"
        )

    return "\n".join(lines) + "\n"


def main() -> None:
    content = render(read_catalog(fetch_catalog()))
    current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else None

    if content == current:
        print(f"{OUTPUT.name} is current")
        return

    temporary = OUTPUT.with_suffix(".md.tmp")
    try:
        temporary.write_text(content, encoding="utf-8")
        os.replace(temporary, OUTPUT)
    finally:
        temporary.unlink(missing_ok=True)

    print(f"Updated {OUTPUT.name}")


if __name__ == "__main__":
    main()
