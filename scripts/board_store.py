from __future__ import annotations

import json
import os
import tempfile
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path

from models import BOARD_TEMPLATE


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def ensure_storage(board_path: str, activity_path: str) -> None:
    board_file = Path(board_path)
    activity_file = Path(activity_path)
    board_file.parent.mkdir(parents=True, exist_ok=True)
    activity_file.parent.mkdir(parents=True, exist_ok=True)
    if not board_file.exists():
        _atomic_write_json(board_file, BOARD_TEMPLATE)
    else:
        try:
            with board_file.open("r", encoding="utf-8") as handle:
                json.load(handle)
        except Exception:
            _atomic_write_json(board_file, BOARD_TEMPLATE)
    activity_file.touch(exist_ok=True)


def load_board(board_path: str) -> dict:
    with open(board_path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict) or "tasks" not in data or "next_id" not in data:
        raise ValueError("Invalid board.json structure")
    return data


def save_board(board_path: str, board: dict) -> None:
    _atomic_write_json(Path(board_path), board)


def append_activity(activity_path: str, entry: dict) -> None:
    line = json.dumps(entry, ensure_ascii=True)
    with open(activity_path, "a", encoding="utf-8") as handle:
        handle.write(line + "\n")


@contextmanager
def locked_board(board_path: str):
    lock_path = f"{board_path}.lock"
    fd = os.open(lock_path, os.O_CREAT | os.O_RDWR, 0o600)
    try:
        try:
            import fcntl

            fcntl.flock(fd, fcntl.LOCK_EX)
        except ImportError:
            pass
        board = load_board(board_path)
        yield board
        save_board(board_path, board)
    finally:
        try:
            import fcntl

            fcntl.flock(fd, fcntl.LOCK_UN)
        except ImportError:
            pass
        os.close(fd)


def _atomic_write_json(path: Path, payload: dict) -> None:
    fd, temp_path = tempfile.mkstemp(prefix=f".{path.name}.", dir=str(path.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2)
            handle.write("\n")
        os.replace(temp_path, path)
    finally:
        if os.path.exists(temp_path):
            os.unlink(temp_path)

