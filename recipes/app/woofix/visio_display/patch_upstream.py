#!/usr/bin/env python3
"""Apply one narrow upstream template fix needed by the demo image."""

import sys
from pathlib import Path


template = Path(sys.argv[1]) / "web/templates/admin_activity.html"
text = template.read_text()
listeners = "\n".join(
    [
        '<script nonce="{{ csp_nonce() }}">',
        "document.getElementById('filter-search')?.addEventListener('input', applyFilters);",
        "document.getElementById('filter-user')?.addEventListener('change', applyFilters);",
        "document.getElementById('filter-action')?.addEventListener('change', applyFilters);",
        "document.getElementById('filter-date-from')?.addEventListener('change', applyFilters);",
        "document.getElementById('filter-date-to')?.addEventListener('change', applyFilters);",
        "document.getElementById('filter-sort')?.addEventListener('change', applyFilters);",
        "document.getElementById('reset-activity-filters')?.addEventListener('click', resetActivityFilters);",
        "</script>",
        "",
    ]
)
external = (
    '<script nonce="{{ csp_nonce() }}" '
    'src="{{ url_for(\'static\', filename=\'js/admin-activity.js\', v=static_version) }}"></script>\n'
)
old = listeners + external
new = external + listeners
if text.count(old) != 1:
    raise SystemExit("activity filter template no longer matches the reviewed upstream source")
template.write_text(text.replace(old, new))
