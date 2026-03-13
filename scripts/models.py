from __future__ import annotations

from dataclasses import dataclass


BOARD_TEMPLATE = {"version": 1, "next_id": 1, "tasks": []}

STATUS_TYPES = {
    "to do": "open",
    "backlog": "unstarted",
    "blocked": "unstarted",
    "planning": "custom",
    "in progress": "custom",
    "update required": "custom",
    "on hold": "custom",
    "complete": "done",
    "review": "done",
    "cancelled": "closed",
}

DONE_TYPES = {"done", "closed"}
PICKABLE_STATUSES = {"to do", "backlog", "planning"}

PRIORITY_MAP = {
    1: "urgent",
    2: "high",
    3: "normal",
    4: "low",
}

PRIORITY_ICONS = {
    "urgent": "[1]",
    "high": "[2]",
    "normal": "[3]",
    "low": "[4]",
    None: "[ ]",
}


@dataclass(frozen=True)
class Paths:
    board: str
    activity: str
    home: str

