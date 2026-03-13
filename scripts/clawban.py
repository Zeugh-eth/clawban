#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys

from board_store import append_activity, ensure_storage, load_board, locked_board, utc_now
from clickup import import_task, load_clickup_key, push_status
from models import DONE_TYPES, Paths, PICKABLE_STATUSES, PRIORITY_MAP, STATUS_TYPES
from render import emit, render_feed, render_task_brief, render_task_detail


def main() -> int:
    paths = resolve_paths()
    ensure_storage(paths.board, paths.activity)
    parser = build_parser()
    args = parser.parse_args()
    if not getattr(args, "command", None):
        parser.print_help()
        return 0
    try:
        return args.func(args, paths)
    except ValueError as exc:
        emit({"error": str(exc)} if args.json else f"Error: {exc}", args.json)
        return 2
    except RuntimeError as exc:
        emit({"error": str(exc)} if args.json else f"Error: {exc}", args.json)
        return 1


def resolve_paths() -> Paths:
    skill_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    home = os.environ.get("CLAWBAN_HOME", skill_root)
    return Paths(
        home=home,
        board=os.environ.get("CLAWBAN_BOARD", os.path.join(home, "board.json")),
        activity=os.environ.get("CLAWBAN_ACTIVITY", os.path.join(home, "activity.jsonl")),
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="clawban", description="Shared Kanban board for OpenClaw agents.")
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON output.")
    sub = parser.add_subparsers(dest="command")

    add = sub.add_parser("add", help="Create a task.")
    add.add_argument("title")
    add.add_argument("--assign", default="")
    add.add_argument("--priority", type=int, choices=range(1, 5))
    add.add_argument("--creator", default="unknown")
    add.add_argument("--status", default="to do")
    add.add_argument("--tags", default="")
    add.add_argument("--description", default="")
    add.add_argument("--parent", default=None)
    add.add_argument("--due", default=None)
    add.set_defaults(func=cmd_add)

    list_cmd = sub.add_parser("list", help="List tasks.")
    list_cmd.add_argument("status", nargs="?")
    list_cmd.set_defaults(func=cmd_list)

    my = sub.add_parser("my", help="List tasks assigned to an agent.")
    my.add_argument("agent")
    my.set_defaults(func=cmd_my)

    view = sub.add_parser("view", help="Show task detail.")
    view.add_argument("task_id")
    view.set_defaults(func=cmd_view)

    status = sub.add_parser("status", help="Update task status.")
    status.add_argument("task_id")
    status.add_argument("status")
    status.add_argument("agent", nargs="?", default="system")
    status.set_defaults(func=cmd_status)

    comment = sub.add_parser("comment", help="Add a comment.")
    comment.add_argument("task_id")
    comment.add_argument("text")
    comment.add_argument("agent", nargs="?", default="system")
    comment.set_defaults(func=cmd_comment)

    assign = sub.add_parser("assign", help="Assign a task.")
    assign.add_argument("task_id")
    assign.add_argument("agent")
    assign.set_defaults(func=cmd_assign)

    priority = sub.add_parser("priority", help="Set task priority.")
    priority.add_argument("task_id")
    priority.add_argument("priority", type=int, choices=range(1, 5))
    priority.set_defaults(func=cmd_priority)

    pick = sub.add_parser("pick", help="Pick the next ready task.")
    pick.add_argument("agent")
    pick.set_defaults(func=cmd_pick)

    feed = sub.add_parser("feed", help="Show recent activity.")
    feed.add_argument("--last", type=int, default=20)
    feed.set_defaults(func=cmd_feed)

    pull = sub.add_parser("pull-clickup", help="Import a ClickUp task.")
    pull.add_argument("task_id")
    pull.set_defaults(func=cmd_pull_clickup)

    push = sub.add_parser("push-clickup", help="Sync a ClickUp task status.")
    push.add_argument("task_id")
    push.set_defaults(func=cmd_push_clickup)

    return parser


def cmd_add(args, paths: Paths) -> int:
    status = normalize_status(args.status)
    assignees = split_csv(args.assign)
    tags = split_csv(args.tags)
    with locked_board(paths.board) as board:
        task_id = f"CLAW-{board['next_id']:03d}"
        board["next_id"] += 1
        now = utc_now()
        task = {
            "id": task_id,
            "source": "clawban",
            "source_id": None,
            "name": args.title,
            "description": args.description,
            "status": {"status": status, "type": STATUS_TYPES.get(status, "custom")},
            "priority": priority_obj(args.priority),
            "assignees": assignees,
            "creator": args.creator,
            "tags": tags,
            "parent": args.parent,
            "due_date": args.due,
            "start_date": None,
            "date_created": now,
            "date_updated": now,
            "date_closed": now if STATUS_TYPES.get(status) in DONE_TYPES else None,
            "dependencies": [],
            "checklists": [],
            "custom_fields": [],
            "comments": [],
        }
        board["tasks"].append(task)
    log(paths, args.creator, "created", task_id, args.title)
    emit(task if args.json else [f"Created {task_id}", render_task_brief(task)], args.json)
    return 0


def cmd_list(args, paths: Paths) -> int:
    board = load_board(paths.board)
    tasks = board["tasks"]
    if args.status:
        status = normalize_status(args.status)
        tasks = [task for task in tasks if task["status"]["status"] == status]
    else:
        tasks = [task for task in tasks if task["status"]["type"] not in DONE_TYPES]
    tasks.sort(key=sort_key)
    emit(tasks if args.json else [render_task_brief(task) for task in tasks] or ["No tasks found"], args.json)
    return 0


def cmd_my(args, paths: Paths) -> int:
    board = load_board(paths.board)
    tasks = [
        task
        for task in board["tasks"]
        if args.agent in task.get("assignees", []) and task["status"]["type"] not in DONE_TYPES
    ]
    tasks.sort(key=sort_key)
    emit(tasks if args.json else [render_task_brief(task) for task in tasks] or [f"No open tasks for {args.agent}"], args.json)
    return 0


def cmd_view(args, paths: Paths) -> int:
    task = require_task(load_board(paths.board), args.task_id)
    emit(task if args.json else render_task_detail(task), args.json)
    return 0


def cmd_status(args, paths: Paths) -> int:
    new_status = normalize_status(args.status)
    with locked_board(paths.board) as board:
        task = require_task(board, args.task_id)
        old_status = task["status"]["status"]
        task["status"] = {"status": new_status, "type": STATUS_TYPES.get(new_status, "custom")}
        task["date_updated"] = utc_now()
        task["date_closed"] = task["date_updated"] if task["status"]["type"] in DONE_TYPES else None
    log(paths, args.agent, "status_change", args.task_id, new_status)
    payload = {"task_id": args.task_id, "old_status": old_status, "new_status": new_status}
    emit(payload if args.json else [f"{args.task_id}: {old_status} -> {new_status}"], args.json)
    return 0


def cmd_comment(args, paths: Paths) -> int:
    with locked_board(paths.board) as board:
        task = require_task(board, args.task_id)
        comment = {"author": args.agent, "text": args.text, "at": utc_now()}
        task["comments"].append(comment)
        task["date_updated"] = comment["at"]
    log(paths, args.agent, "commented", args.task_id, args.text)
    emit(comment if args.json else [f"Comment added to {args.task_id} by {args.agent}"], args.json)
    return 0


def cmd_assign(args, paths: Paths) -> int:
    with locked_board(paths.board) as board:
        task = require_task(board, args.task_id)
        task["assignees"] = [args.agent]
        task["date_updated"] = utc_now()
    log(paths, "system", "assigned", args.task_id, args.agent)
    emit({"task_id": args.task_id, "assignees": [args.agent]} if args.json else [f"{args.task_id} assigned to {args.agent}"], args.json)
    return 0


def cmd_priority(args, paths: Paths) -> int:
    with locked_board(paths.board) as board:
        task = require_task(board, args.task_id)
        task["priority"] = priority_obj(args.priority)
        task["date_updated"] = utc_now()
    log(paths, "system", "priority_change", args.task_id, str(args.priority))
    emit(task["priority"] if args.json else [f"{args.task_id} priority set to {task['priority']['priority']}"], args.json)
    return 0


def cmd_pick(args, paths: Paths) -> int:
    with locked_board(paths.board) as board:
        candidates = [
            task
            for task in board["tasks"]
            if args.agent in task.get("assignees", []) and task["status"]["status"] in PICKABLE_STATUSES
        ]
        candidates.sort(key=sort_key)
        if not candidates:
            emit({"task": None} if args.json else [f"No ready tasks for {args.agent}"], args.json)
            return 0
        task = candidates[0]
        task["status"] = {"status": "in progress", "type": STATUS_TYPES["in progress"]}
        task["date_updated"] = utc_now()
        picked_id = task["id"]
    log(paths, args.agent, "picked", picked_id, "auto-picked")
    emit(task if args.json else [f"Picked {task['id']}", render_task_brief(task)], args.json)
    return 0


def cmd_feed(args, paths: Paths) -> int:
    entries = []
    with open(paths.activity, "r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    entries = entries[-args.last :]
    emit(entries if args.json else render_feed(entries), args.json)
    return 0


def cmd_pull_clickup(args, paths: Paths) -> int:
    clickup_key = os.environ.get("CLICKUP_API_KEY", "") or load_clickup_key()
    if not clickup_key:
        raise RuntimeError("CLICKUP_API_KEY not set")
    with locked_board(paths.board) as board:
        task = import_task(board, clickup_key, args.task_id)
    log(paths, "system", "imported_clickup", task["id"], "Imported from ClickUp")
    emit(task if args.json else [f"Imported {task['id']}", render_task_brief(task)], args.json)
    return 0


def cmd_push_clickup(args, paths: Paths) -> int:
    clickup_key = os.environ.get("CLICKUP_API_KEY", "") or load_clickup_key()
    if not clickup_key:
        raise RuntimeError("CLICKUP_API_KEY not set")
    board = load_board(paths.board)
    task = require_task(board, args.task_id)
    if task.get("source") != "clickup":
        raise ValueError(f"{args.task_id} is not a ClickUp task")
    push_status(task, clickup_key)
    log(paths, "system", "pushed_clickup", args.task_id, "Synced to ClickUp")
    emit(task if args.json else [f"Synced {args.task_id} to ClickUp"], args.json)
    return 0


def priority_obj(value: int | None) -> dict:
    return {"id": value, "priority": PRIORITY_MAP.get(value)} if value else {"id": None, "priority": None}


def normalize_status(value: str) -> str:
    normalized = value.strip().lower()
    if not normalized:
        raise ValueError("status cannot be empty")
    return normalized


def split_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


def require_task(board: dict, task_id: str) -> dict:
    for task in board["tasks"]:
        if task["id"] == task_id:
            return task
    raise ValueError(f"Task {task_id} not found")


def sort_key(task: dict):
    priority = task.get("priority", {}).get("id") or 99
    return (priority, task.get("date_updated") or "", task["id"])


def log(paths: Paths, agent: str, action: str, task_id: str, detail: str) -> None:
    append_activity(
        paths.activity,
        {
            "timestamp": utc_now(),
            "agent": agent,
            "action": action,
            "task_id": task_id,
            "detail": detail,
        },
    )


if __name__ == "__main__":
    sys.exit(main())
