#!/usr/bin/env python3
import math
import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


WIDTH, HEIGHT = 1280, 720
REGULAR = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


SLIDES = [
    ("01-week-at-a-glance.png", "COMPANY", "Northstar Relay — week at a glance", ["Monday · Welcome Theo and complete access checks", "Tuesday · Lumen renewal review", "Next week · Release 2.8 target"], "3", "active stories", (30, 64, 175), (54, 211, 153)),
    ("02-welcome-theo-martin.png", "PEOPLE", "Welcome, Theo Martin", ["Software engineer · Engineering", "09:30 welcome session with Imani and Jon", "Architecture and pairing blocks are ready"], "MON", "first day", (89, 47, 145), (250, 176, 5)),
    ("03-theo-first-week.png", "ONBOARDING", "Theo’s first-week checklist", ["Laptop, email, chat and repository — ready", "Architecture session with Jon — booked", "Staging access — owner still needed"], "4/5", "items ready", (15, 82, 87), (45, 212, 191)),
    ("04-release-2-8-readiness.png", "RELEASE 2.8", "One decision remains", ["Audit page copy is final", "50k export load test passed", "Cancellation cleanup is still the release gate"], "1", "open gate", (69, 26, 111), (168, 85, 247)),
    ("05-export-load-test.png", "ENGINEERING", "Export worker load test", ["50,000 rows · passed", "75,000 rows · validation in progress", "Cancelled run · partial object cleanup blocked"], "50k", "passed", (6, 78, 59), (34, 197, 94)),
    ("06-lumen-renewal.png", "CUSTOMER", "Lumen renewal review", ["Usage is up 38% since February", "Manual export retry is the safe workaround", "Do not promise 2.8 before cancellation tests pass"], "+38%", "usage", (20, 61, 105), (14, 165, 233)),
    ("07-customer-support-focus.png", "SUPPORT", "Customer focus this week", ["Lumen · scheduled export timeout", "Ember · overnight report customer column", "Harbor · retention and audit-log review"], "3", "active threads", (104, 34, 52), (244, 63, 94)),
    ("08-security-review.png", "CUSTOMER TRUST", "Security review follow-up", ["Confirm retention policy", "Document export access controls", "Name the audit-log owner"], "TODAY", "response due", (30, 41, 59), (234, 88, 12)),
    ("09-audit-page-review.png", "PRODUCT", "Audit page review", ["Timezone label issue 322 is visual only", "The fix stays outside the export branch", "Add the screenshot to the release review"], "322", "tracked issue", (53, 34, 95), (139, 92, 246)),
    ("10-office-delivery.png", "LONDON OFFICE", "Theo’s desk delivery", ["Monday · 08:00–10:00", "Desk and riser in one shipment", "No signature is required"], "08–10", "delivery window", (63, 44, 20), (245, 158, 11)),
    ("11-august-expenses.png", "OPERATIONS", "August expense reminder", ["Submit each amount and customer before 16:00", "A missing receipt can follow on Monday", "Questions · Noor Alvarez"], "16:00", "today", (57, 47, 19), (234, 179, 8)),
    ("12-cloudharbor-note.png", "INFRASTRUCTURE", "CloudHarbor operations note", ["Queue visibility metrics are available", "Paris region is now open", "Toronto maintenance does not affect London"], "OK", "London region", (13, 67, 78), (6, 182, 212)),
    ("13-team-locations.png", "TEAM", "Northstar Relay works across Europe", ["London · leadership and partnerships", "Bristol, Hamburg, Leeds · engineering", "Madrid, Berlin, Dublin, Manchester · operations"], "10", "team members", (27, 45, 87), (59, 130, 246)),
    ("14-operating-principles.png", "HOW WE WORK", "Accurate answers. Safe changes.", ["State what is known and unknown", "Test the risky path before merge", "Give every loose end a clear owner"], "3", "operating principles", (50, 32, 69), (217, 70, 239)),
    ("15-release-calendar.png", "CALENDAR", "Key sessions", ["09:30 · Welcome Theo", "11:30 · Release 2.8 go or no-go", "13:00 · Lumen renewal review"], "3", "team sessions", (7, 67, 64), (20, 184, 166)),
    ("16-support-workaround.png", "CUSTOMER UPDATE", "Safe export workaround", ["Use the manual retry with the saved export", "Keep the browser open until download starts", "Scheduled exports still stop at 120 seconds"], "120s", "known limit", (73, 24, 32), (239, 68, 68)),
    ("17-release-notes.png", "PRODUCT", "Release notes are ready", ["Saved views and audit page copy are final", "Export retry wording remains conditional", "Elena will update after the release gate closes"], "2.8", "next release", (42, 34, 86), (99, 102, 241)),
    ("18-screen-guide.png", "DISPLAY NETWORK", "Four focused playlists", ["Reception · people and company updates", "Team Hub · release and engineering", "Support Room · customer commitments"], "4", "managed screens", (22, 48, 77), (16, 185, 129)),
]


def font(path, size):
    return ImageFont.truetype(path, size)


def wrap(draw, text, face, max_width):
    words = text.split()
    lines, line = [], ""
    for word in words:
        candidate = f"{line} {word}".strip()
        if draw.textbbox((0, 0), candidate, font=face)[2] <= max_width:
            line = candidate
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def draw_slide(path, category, title, bullets, stat, stat_label, base, accent):
    image = Image.new("RGB", (WIDTH, HEIGHT), base)
    draw = ImageDraw.Draw(image)

    for i in range(8):
        radius = 180 + i * 28
        alpha = max(18, 78 - i * 8)
        layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
        ldraw = ImageDraw.Draw(layer)
        ldraw.ellipse((WIDTH - radius, -radius // 2, WIDTH + radius // 2, radius), fill=(*accent, alpha))
        image = Image.alpha_composite(image.convert("RGBA"), layer).convert("RGB")
        draw = ImageDraw.Draw(image)

    panel = tuple(round(channel * 0.78 + 255 * 0.22) for channel in base)
    border = tuple(round(channel * 0.62 + 255 * 0.38) for channel in base)
    draw.rounded_rectangle((64, 52, 1216, 668), radius=34, fill=panel, outline=border, width=2)
    draw.rounded_rectangle((94, 82, 292, 124), radius=21, fill=accent)
    draw.text((114, 91), category, font=font(BOLD, 19), fill="white")

    title_face = font(BOLD, 50)
    y = 158
    for line in wrap(draw, title, title_face, 765)[:2]:
        draw.text((94, y), line, font=title_face, fill="white")
        y += 62

    y = max(y + 28, 298)
    body_face = font(REGULAR, 25)
    for bullet in bullets:
        draw.ellipse((98, y + 9, 112, y + 23), fill=accent)
        lines = wrap(draw, bullet, body_face, 740)
        for index, line in enumerate(lines[:2]):
            draw.text((130, y + index * 34), line, font=body_face, fill=(230, 238, 250))
        y += max(54, len(lines[:2]) * 34 + 16)

    draw.rounded_rectangle((904, 262, 1168, 530), radius=28, fill=accent)
    stat_face = font(BOLD, 70 if len(stat) <= 4 else 54)
    stat_box = draw.textbbox((0, 0), stat, font=stat_face)
    draw.text((int(1036 - (stat_box[2] - stat_box[0]) / 2), 326), stat, font=stat_face, fill="white")
    label_face = font(BOLD, 18)
    label_lines = wrap(draw, stat_label.upper(), label_face, 200)
    for index, line in enumerate(label_lines[:2]):
        box = draw.textbbox((0, 0), line, font=label_face)
        draw.text((int(1036 - (box[2] - box[0]) / 2), 420 + index * 24), line, font=label_face, fill=(255, 255, 255))

    draw.line((94, 610, 1168, 610), fill=border, width=2)
    draw.text((94, 626), "NORTHSTAR RELAY", font=font(BOLD, 16), fill=(205, 218, 236))
    draw.text((1017, 626), "LONDON", font=font(BOLD, 16), fill=(205, 218, 236))
    image.save(path, optimize=True)


def main():
    output = Path(sys.argv[1])
    output.mkdir(parents=True, exist_ok=True)
    for slide in SLIDES:
        draw_slide(output / slide[0], *slide[1:])


if __name__ == "__main__":
    main()
