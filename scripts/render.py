from __future__ import annotations

import json
from typing import Iterable

from models import PRIORITY_ICONS


def emit(payload, as_json: bool) -> None:
    if as_json:
        print(json.dumps(payload, indent=2))
        return
    if isinstance(payload, str):
        print(payload)
        return
    if isinstance(payload, list):
        for line in payload:
            print(line)
        return
    print(payload)


def render_task_brief(task: dict) -> str:
    label = task.get("priority", {}).get("priority")
    icon = PRIORITY_ICONS.get(label, "[ ]")
    assignees = ", ".join(task.get("assignees", [])) or "unassigned"
    return f"{icon} {task['id']} [{task['status']['status']}] {task['name']} -> {assignees}"


def render_task_detail(task: dict) -> list[str]:
    lines = [
        f"{task['id']}: {task['name']}",
        f"Status: {task['status']['status']}",
        f"Priority: {task.get('priority', {}).get('priority') or 'none'}",
        f"Assigned: {', '.join(task.get('assignees', [])) or 'unassigned'}",
        f"Creator: {task.get('creator') or 'unknown'}",
        f"Tags: {', '.join(task.get('tags', [])) or 'none'}",
        f"Created: {task.get('date_created') or '?'}",
        f"Updated: {task.get('date_updated') or '?'}",
    ]
    if task.get("due_date"):
        lines.append(f"Due: {task['due_date']}")
    if task.get("parent"):
        lines.append(f"Parent: {task['parent']}")
    if task.get("source") == "clickup":
        lines.append(f"ClickUp: {task.get('source_id') or '?'}")
    if task.get("description"):
        lines.extend(["", "Description:", task["description"]])
    comments = task.get("comments") or []
    if comments:
        lines.append("")
        lines.append(f"Comments ({len(comments)}):")
        for comment in comments:
            lines.append(f"[{comment['at']}] {comment['author']}: {comment['text']}")
    return lines


def render_feed(entries: Iterable[dict]) -> list[str]:
    entries = list(entries)
    if not entries:
        return ["No activity yet"]
    lines = [f"Activity feed ({len(entries)} entries)"]
    for entry in entries:
        lines.append(
            f"[{entry['timestamp'][:16]}] {entry['agent']:>8} {entry['action']:>15} {entry.get('task_id', '')} {entry.get('detail', '')[:80]}"
        )
    return lines

