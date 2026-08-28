#!/usr/bin/env python3
import json
import os
import secrets
import shutil
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, "/app/web")

from app import create_app
from db import ActivityLog, ClientHeartbeat, EncodeJob, User, UserRole, db
from services.config_svc import load_config, save_config
from services.media_svc import generate_standard_renditions, set_media_upload_attribution
from services.rbac_svc import get_role_by_name
from services.search_index_svc import reseed_search_index
from werkzeug.security import generate_password_hash


SEED_VERSION = "northstar-visio-v2"
MEDIA = [
    "01-week-at-a-glance.png", "02-welcome-theo-martin.png", "03-theo-first-week.png",
    "04-release-2-8-readiness.png", "05-export-load-test.png", "06-lumen-renewal.png",
    "07-customer-support-focus.png", "08-security-review.png", "09-audit-page-review.png",
    "10-office-delivery.png", "11-august-expenses.png", "12-cloudharbor-note.png",
    "13-team-locations.png", "14-operating-principles.png", "15-release-calendar.png",
    "16-support-workaround.png", "17-release-notes.png", "18-screen-guide.png",
]


PEOPLE = [
    ("jon", "editor", ["team-hub"]),
    ("noor", "editor", ["reception", "operations"]),
    ("elena", "editor", ["team-hub", "reception"]),
    ("samira", "editor", ["support-room"]),
    ("lucas", "editor", ["team-hub"]),
    ("hana", "editor", ["team-hub"]),
    ("david", "editor", ["reception", "support-room"]),
    ("imani", "editor", ["reception", "team-hub"]),
    ("theo", "viewer", ["team-hub"]),
]


def ago(days=0, hours=0, minutes=0):
    value = datetime.now(timezone.utc) - timedelta(days=days, hours=hours, minutes=minutes)
    return value.strftime("%Y-%m-%dT%H:%M:%S")


def copy_media():
    source = Path("/opt/droplive-visio-seed/original")
    target = Path(os.environ["MEDIA_DIR"]) / "original"
    target.mkdir(parents=True, exist_ok=True)
    for name in MEDIA:
        destination = target / name
        if not destination.exists():
            shutil.copy2(source / name, destination)


def build_config():
    today = datetime.now().date()
    active_start = (today - timedelta(days=2)).isoformat()
    active_end = (today + timedelta(days=5)).isoformat()
    future_end = (today + timedelta(days=10)).isoformat()
    archived_start = (today - timedelta(days=18)).isoformat()
    archived_end = (today - timedelta(days=12)).isoformat()

    groups = {
        MEDIA[0]: ["Company updates"], MEDIA[1]: ["Onboarding", "Company updates"],
        MEDIA[2]: ["Onboarding"], MEDIA[3]: ["Release 2.8"], MEDIA[4]: ["Release 2.8", "Engineering"],
        MEDIA[5]: ["Customer operations", "Lumen"], MEDIA[6]: ["Customer operations"],
        MEDIA[7]: ["Customer operations", "Security"], MEDIA[8]: ["Release 2.8", "Product"],
        MEDIA[9]: ["Office operations", "Onboarding"], MEDIA[10]: ["Office operations"],
        MEDIA[11]: ["Infrastructure"], MEDIA[12]: ["Company updates"], MEDIA[13]: ["Company updates"],
        MEDIA[14]: ["Calendar", "Company updates"], MEDIA[15]: ["Customer operations", "Lumen"],
        MEDIA[16]: ["Release 2.8", "Product"], MEDIA[17]: ["Display operations"],
    }

    reception = [MEDIA[i] for i in (0, 1, 9, 12, 13, 14, 17)]
    team_hub = [MEDIA[i] for i in (0, 2, 3, 4, 8, 12, 14, 16)]
    support = [MEDIA[i] for i in (5, 6, 7, 15, 11)]
    operations = [MEDIA[i] for i in (0, 9, 10, 11, 14, 17)]

    def slot(time_start, time_end, date_start=active_start, date_end=future_end):
        return {
            "date_start": date_start,
            "date_end": date_end,
            "time_start": time_start,
            "time_end": time_end,
        }

    # Every display has a real working-day plan. The small gaps are intentional:
    # they make the weekly gap detector useful without creating fake conflicts.
    schedules = {
        MEDIA[0]: slot("08:00", "10:00"),
        MEDIA[13]: slot("10:00", "13:00"),
        MEDIA[14]: slot("14:00", "18:00"),
    }
    reception_schedules = {
        MEDIA[1]: slot("08:00", "10:30"),
        MEDIA[9]: slot("10:30", "13:00"),
        MEDIA[12]: slot("14:00", "18:00"),
    }
    team_hub_schedules = {
        MEDIA[3]: slot("08:30", "11:00"),
        MEDIA[4]: slot("11:00", "14:00"),
        MEDIA[16]: slot("14:30", "18:30"),
    }
    support_schedules = {
        MEDIA[6]: slot("07:00", "11:00"),
        MEDIA[5]: slot("11:00", "15:00"),
        MEDIA[15]: slot("15:00", "19:00"),
    }
    operations_schedules = {
        MEDIA[10]: slot("07:30", "10:00"),
        MEDIA[11]: slot("10:00", "13:00"),
        MEDIA[17]: slot("14:00", "18:00"),
    }

    return {
        "droplive_seed_version": SEED_VERSION,
        "app_name": "Northstar Displays",
        "default_screen_name": "Northstar London",
        "default_halo_color": "#2563eb",
        "order": reception,
        "durations": {name: 14 + (index % 4) * 3 for index, name in enumerate(MEDIA)},
        "disabled": [],
        "schedules": schedules,
        "groups": groups,
        "group_pools": {"Company updates": 3, "Release 2.8": 3, "Customer operations": 3},
        "group_screens": {
            "Onboarding": ["reception", "team-hub"],
            "Release 2.8": ["team-hub"],
            "Customer operations": ["support-room"],
            "Office operations": ["operations", "reception"],
            "Security": ["support-room"],
        },
        "disabled_groups": [],
        "screens": {
            "reception": {"order": reception, "disabled": [], "disabled_groups": [], "durations": {}, "schedules": reception_schedules, "halo_color": "#0ea5e9"},
            "team-hub": {"order": team_hub, "disabled": [], "disabled_groups": [], "durations": {}, "schedules": team_hub_schedules, "halo_color": "#8b5cf6"},
            "support-room": {"order": support, "disabled": [], "disabled_groups": [], "durations": {}, "schedules": support_schedules, "halo_color": "#f43f5e"},
            "operations": {"order": operations, "disabled": [], "disabled_groups": [], "durations": {}, "schedules": operations_schedules, "halo_color": "#14b8a6"},
        },
        "broadcast_links": {},
        "campaigns": [
            {"id": "welcome-theo", "name": "Welcome Theo", "start_date": active_start, "end_date": active_end, "priority": 240, "enabled": True, "archived": False, "screens": ["reception"], "groups": ["Onboarding"], "media": [MEDIA[1], MEDIA[2]], "created_by": "imani", "created_at": ago(days=5), "updated_at": ago(hours=4)},
            {"id": "release-2-8", "name": "Release 2.8 readiness", "start_date": active_start, "end_date": future_end, "priority": 220, "enabled": True, "archived": False, "screens": ["team-hub"], "groups": ["Release 2.8"], "media": [MEDIA[3], MEDIA[4], MEDIA[16]], "created_by": "elena", "created_at": ago(days=8), "updated_at": ago(hours=2)},
            {"id": "lumen-renewal", "name": "Lumen renewal preparation", "start_date": active_start, "end_date": active_end, "priority": 210, "enabled": True, "archived": False, "screens": ["support-room"], "groups": ["Lumen"], "media": [MEDIA[5], MEDIA[15]], "created_by": "samira", "created_at": ago(days=6), "updated_at": ago(hours=1)},
            {"id": "august-operations", "name": "August operations close", "start_date": active_start, "end_date": active_end, "priority": 120, "enabled": True, "archived": False, "screens": ["operations"], "groups": ["Office operations"], "media": [MEDIA[10]], "created_by": "noor", "created_at": ago(days=7), "updated_at": ago(days=1)},
            {"id": "audit-page-review", "name": "Audit page review", "start_date": archived_start, "end_date": archived_end, "priority": 150, "enabled": False, "archived": True, "screens": ["team-hub"], "groups": ["Product"], "media": [MEDIA[8]], "created_by": "hana", "created_at": ago(days=19), "updated_at": ago(days=12)},
        ],
        "priority_alert": {"message": "", "updated_at": None},
        "events": [
            {"label": "Welcome Theo", "date": (today + timedelta(days=1)).isoformat()},
            {"label": "Lumen renewal review", "date": (today + timedelta(days=2)).isoformat()},
            {"label": "Release 2.8 target", "date": (today + timedelta(days=7)).isoformat()},
        ],
        "meteo_ville": "London",
        "meteo_lat": 51.5074,
        "meteo_lng": -0.1278,
        "meteo_tz": "Europe/London",
        "features": {
            "upload": True, "announcements": True, "menus": True, "videos": True,
            "delete": True, "compress": True, "ephemeris": False, "campaigns": True,
            "schedule": True, "groups": True, "screens": True,
            "priority_alert": True, "activity": True,
        },
        "activity_log": {"auto_delete_enabled": True, "retention_days": 90, "max_rows": 20000},
        "client_watchdog": {"check_interval_seconds": 30, "grace_period_seconds": 90, "consecutive_failures_before_reboot": 2},
        "backup_remote": {"enabled": False, "url": "", "username": "", "password": ""},
        "backup_schedule": {"enabled": False, "time": "02:00", "copy_to_smb": False},
        "backup_retention": {"max_versions": 5},
    }


def seed_users():
    owner = db.session.get(User, "maya")
    owner.language = "en"
    owner.theme = "bleu"
    owner.must_change_password = False
    for username, role_name, screens in PEOPLE:
        user = db.session.get(User, username)
        if user is None:
            user = User(
                username=username,
                password_hash=generate_password_hash(secrets.token_urlsafe(32)),
                superadmin=False,
                permissions="[]",
                screens=json.dumps(screens),
                theme="bleu",
                language="en",
                must_change_password=False,
            )
            db.session.add(user)
            db.session.flush()
        role = get_role_by_name(role_name)
        if role and db.session.get(UserRole, (username, role.id)) is None:
            db.session.add(UserRole(username=username, role_id=role.id))
    db.session.commit()


def seed_activity():
    if ActivityLog.query.filter_by(details=f"seed:{SEED_VERSION}").first():
        return
    events = [
        (12, "imani", "upload", MEDIA[1], "Welcome slide exported from the announcement editor"),
        (11, "elena", "campaign", None, "created:Release 2.8 readiness"),
        (10, "lucas", "upload", MEDIA[4], "50k load-test result added to Team Hub"),
        (9, "samira", "campaign", None, "created:Lumen renewal preparation"),
        (8, "noor", "config", None, "screen added:operations"),
        (8, "david", "upload", MEDIA[5], "Renewal review card approved for Support Room"),
        (7, "hana", "upload", MEDIA[8], "Audit-page review card updated for issue 322"),
        (6, "maya", "config", None, "default screen name:Northstar London"),
        (6, "imani", "config", MEDIA[2], "group:Onboarding linked to reception and team-hub"),
        (5, "noor", "upload", MEDIA[10], "August operations reminder published"),
        (5, "elena", "campaign", None, "updated:Release 2.8 readiness"),
        (4, "jon", "toggle", MEDIA[4], "enabled on team-hub"),
        (4, "samira", "upload", MEDIA[15], "Manual export workaround approved"),
        (3, "maya", "config", None, "application name:Northstar Displays"),
        (3, "david", "toggle", MEDIA[5], "assigned to support-room"),
        (2, "noor", "campaign", None, "created:August operations close"),
        (2, "lucas", "config", MEDIA[4], "duration:20 seconds"),
        (1, "hana", "campaign", None, "archived:Audit page review"),
        (1, "imani", "campaign", None, "updated:Welcome Theo"),
        (0, "noor", "config", MEDIA[17], "display slots:operations weekday plan published"),
        (0, "maya", "login", None, f"seed:{SEED_VERSION}"),
    ]
    for index, (days, username, action, filename, details) in enumerate(events):
        timestamp = datetime.now(timezone.utc) - timedelta(days=days, hours=index % 7, minutes=index * 3)
        db.session.add(ActivityLog(
            timestamp=timestamp.strftime("%Y-%m-%dT%H:%M:%S"), username=username,
            action=action, filename=filename, details=details,
        ))
    db.session.commit()


def seed_clients():
    clients = [
        ("northstar-reception-01", "reception-display", "Reception", "reception", "192.0.2.21", 18.4, 1240, 4096, 47.2, 18340, 30000, "1920x1080", 1),
        ("northstar-teamhub-01", "team-hub-display", "Team Hub", "team-hub", "192.0.2.22", 23.1, 1488, 4096, 49.0, 17120, 30000, "3840x2160", 2),
        ("northstar-support-01", "support-room-display", "Support Room", "support-room", "192.0.2.23", 16.7, 1120, 4096, 44.8, 19240, 30000, "1920x1080", 1),
        ("northstar-ops-01", "operations-display", "Operations", "operations", "192.0.2.24", 12.9, 980, 4096, 43.5, 20110, 30000, "1920x1080", 3),
    ]
    now = datetime.now(timezone.utc)
    for machine_id, hostname, name, screen, ip, cpu, ram, total_ram, temp, free_disk, total_disk, resolution, minutes in clients:
        row = db.session.get(ClientHeartbeat, machine_id) or ClientHeartbeat(machine_id=machine_id)
        row.hostname = hostname
        row.client_name = name
        row.screen_name = screen
        row.ip_address = ip
        row.server_url = "https://display.northstar-relay.droplive.test"
        row.client_version = "2.0.4"
        row.uptime_seconds = 345600 + minutes * 3600
        row.cpu_load_percent = cpu
        row.ram_used_mb = ram
        row.ram_total_mb = total_ram
        row.temperature_c = temp
        row.disk_free_mb = free_disk
        row.disk_total_mb = total_disk
        row.resolution = resolution
        row.last_error = ""
        row.last_seen = (now - timedelta(minutes=minutes)).strftime("%Y-%m-%dT%H:%M:%S")
        db.session.merge(row)
    db.session.commit()


def seed_jobs():
    jobs = [
        ("a28f0101", MEDIA[1], 6.8, 1.1, 6.2, 5),
        ("a28f0102", MEDIA[3], 7.2, 1.3, 5.5, 4),
        ("a28f0103", MEDIA[5], 6.5, 1.0, 6.5, 3),
        ("a28f0104", MEDIA[7], 7.0, 1.2, 5.8, 2),
        ("a28f0105", MEDIA[15], 6.9, 1.1, 6.3, 1),
    ]
    for job_id, filename, before, after, ratio, days in jobs:
        if db.session.get(EncodeJob, job_id):
            continue
        db.session.add(EncodeJob(
            id=job_id, filename=filename, status="done", added=ago(days=days, hours=3),
            started=ago(days=days, hours=2, minutes=58), finished=ago(days=days, hours=2, minutes=56),
            before_mb=before, after_mb=after, ratio=ratio, message="Prepared for display",
        ))
    db.session.commit()


def prepare_media():
    for index, filename in enumerate(MEDIA):
        generate_standard_renditions(filename)
        set_media_upload_attribution(filename, ["imani", "elena", "samira", "noor"][index % 4], ago(days=12 - (index % 10), hours=index % 6))


def main():
    copy_media()
    app = create_app(start_scheduler=False)
    with app.app_context():
        cfg = load_config()
        already_seeded = cfg.get("droplive_seed_version") == SEED_VERSION
        if not already_seeded:
            seed_users()
            save_config(build_config())
            seed_activity()
            seed_clients()
            seed_jobs()
        prepare_media()
        reseed_search_index()
    print("[droplive] Visio-Display Northstar demo is ready", flush=True)


if __name__ == "__main__":
    main()
