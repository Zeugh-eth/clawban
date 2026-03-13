from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone

from board_store import utc_now
from models import PRIORITY_MAP, STATUS_TYPES


def load_clickup_key() -> str:
    try:
        with open("/root/.openclaw/openclaw.json", "r", encoding="utf-8") as handle:
            data = json.load(handle)
        return data.get("env", {}).get("vars", {}).get("CLICKUP_API_KEY", "")
    except Exception:
        return ""


def import_task(board: dict, clickup_key: str, task_id: str) -> dict:
    result = subprocess.run(
        [
            "curl",
            "-sf",
            f"https://api.clickup.com/api/v2/task/{task_id}",
            "-H",
            f"Authorization: {clickup_key}",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "ClickUp fetch failed")

    payload = json.loads(result.stdout)
    existing = next((task for task in board["tasks"] if task.get("source_id") == payload["id"]), None)
    if existing:
        return existing

    task = {
        "id": f"CU-{payload['id']}",
        "source": "clickup",
        "source_id": payload["id"],
        "name": payload.get("name", ""),
        "description": payload.get("text_content", ""),
        "status": {
            "status": _normalize_status(payload.get("status", {}).get("status", "to do")),
            "type": STATUS_TYPES.get(_normalize_status(payload.get("status", {}).get("status", "to do")), "custom"),
        },
        "priority": _priority_from_clickup(payload.get("priority")),
        "assignees": _assignees_from_clickup(payload.get("assignees", [])),
        "creator": "clickup",
        "tags": [tag.get("name", "") for tag in payload.get("tags", [])],
        "parent": f"CU-{payload['parent']}" if payload.get("parent") else None,
        "due_date": _ms_to_iso(payload.get("due_date")),
        "start_date": _ms_to_iso(payload.get("start_date")),
        "date_created": _ms_to_iso(payload.get("date_created")) or utc_now(),
        "date_updated": _ms_to_iso(payload.get("date_updated")) or utc_now(),
        "date_closed": _ms_to_iso(payload.get("date_closed")),
        "dependencies": [],
        "checklists": [],
        "custom_fields": payload.get("custom_fields", []),
        "comments": [],
    }
    board["tasks"].append(task)
    return task


def push_status(task: dict, clickup_key: str) -> None:
    result = subprocess.run(
        [
            "curl",
            "-sf",
            "-X",
            "PUT",
            f"https://api.clickup.com/api/v2/task/{task['source_id']}",
            "-H",
            f"Authorization: {clickup_key}",
            "-H",
            "Content-Type: application/json",
            "-d",
            json.dumps({"status": task["status"]["status"]}),
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "ClickUp sync failed")


def _normalize_status(raw: str) -> str:
    return raw.lower().lstrip("[0123456789] ").strip()


def _priority_from_clickup(priority: dict | None) -> dict:
    if not priority:
        return {"id": None, "priority": None}
    pid = int(priority["id"])
    return {"id": pid, "priority": PRIORITY_MAP.get(pid, priority.get("priority"))}


def _assignees_from_clickup(assignees: list[dict]) -> list[str]:
    result = []
    for assignee in assignees:
        if assignee.get("id") == 84844111:
            result.append("zeugh")
        else:
            result.append(str(assignee.get("username") or assignee.get("id") or ""))
    return result


def _ms_to_iso(value) -> str | None:
    if not value:
        return None
    return datetime.fromtimestamp(int(value) / 1000, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

