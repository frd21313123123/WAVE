#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
import re


@dataclass
class TaskRecord:
    task_id: str
    question: str
    options: list[str]
    url: str | None
    title: str | None
    source_file: str
    screenshot_file: str | None
    captured_at: str


def repair_mojibake(text: str) -> str:
    repaired = text
    for _ in range(4):
        if "Ð" not in repaired and "Ñ" not in repaired and "Â" not in repaired:
            break
        try:
            candidate = repaired.encode("latin1", errors="ignore").decode("utf-8", errors="ignore")
        except Exception:
            break
        if not candidate or candidate == repaired:
            break
        repaired = candidate
    return repaired


def read_text(path: Path) -> str:
    return repair_mojibake(path.read_text(encoding="utf-8", errors="replace"))


def extract_url(text: str) -> str | None:
    match = re.search(r"Page URL:\s*(\S+)", text)
    return match.group(1) if match else None


def extract_title(text: str) -> str | None:
    match = re.search(r"Page Title:\s*(.+)", text)
    return match.group(1).strip() if match else None


def extract_question(text: str) -> str | None:
    if "Вы ответили на оценку" in text:
        return None

    candidates: list[str] = []
    for match in re.finditer(r'paragraph\s+\[ref=[^\]]+\]:\s*(?:"([^"]+)"|(.+))', text):
        value = (match.group(1) or match.group(2) or "").strip()
        if not value:
            continue
        if value.startswith("© "):
            continue
        if "round-trip time" in value:
            continue
        if value in {"Тренировочный тест", "л.р.1 - Политропные процессы", "Работа над ошибками"}:
            continue
        candidates.append(value)

    if not candidates:
        return None

    def score(value: str) -> tuple[int, int]:
        weight = len(value)
        if "?" in value:
            weight += 40
        if "________" in value:
            weight += 30
        if any(word in value for word in ("Выберите", "Укажите", "Восстановите", "Чему", "Какой", "Как", "Что")):
            weight += 20
        if "Ответ верный" in value or "Ответ неверный" in value:
            weight -= 200
        return (weight, len(value))

    return max(candidates, key=score)


def extract_options(text: str) -> list[str]:
    found: list[str] = []
    seen: set[str] = set()
    for line in text.splitlines():
        match = re.search(r'- row "(\d\.\s*.+)"', line)
        if not match:
            continue
        value = match.group(1).strip()
        if value not in seen:
            seen.add(value)
            found.append(value)
    return found


def build_task_id(question: str, options: list[str]) -> str:
    payload = question.strip() + "\n" + "\n".join(options)
    return hashlib.sha1(payload.encode("utf-8")).hexdigest()[:16]


def load_existing_ids(path: Path) -> set[str]:
    if not path.exists():
        return set()
    result: set[str] = set()
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        task_id = obj.get("task_id")
        if isinstance(task_id, str):
            result.add(task_id)
    return result


def append_jsonl(path: Path, record: TaskRecord) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record.__dict__, ensure_ascii=False) + "\n")


def append_text_log(path: Path, record: TaskRecord) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        f"[{record.captured_at}] {record.task_id}",
        f"Question: {record.question}",
    ]
    if record.options:
        lines.append("Options:")
        lines.extend(f"- {item}" for item in record.options)
    if record.url:
        lines.append(f"URL: {record.url}")
    if record.screenshot_file:
        lines.append(f"Screenshot: {record.screenshot_file}")
    lines.append(f"Source: {record.source_file}")
    lines.append("")
    with path.open("a", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


def copy_capture(src: Path | None, captures_dir: Path, task_id: str, suffix: str) -> str | None:
    if not src or not src.exists():
        return None
    captures_dir.mkdir(parents=True, exist_ok=True)
    dst = captures_dir / f"{task_id}{suffix}"
    shutil.copy2(src, dst)
    return str(dst)


def main() -> int:
    parser = argparse.ArgumentParser(description="Save current browser task text and screenshot into project archives.")
    parser.add_argument("snapshot", nargs="?", default="data/latest-task-snapshot.md", help="Browser snapshot path")
    parser.add_argument("--screenshot", default="data/latest-task.png", help="Latest screenshot path")
    parser.add_argument("--output", default="data/browser_tasks_clean.jsonl", help="JSONL archive path")
    parser.add_argument("--text-output", default="data/browser_tasks_clean.txt", help="Text archive path")
    parser.add_argument("--captures-dir", default="data/captures", help="Directory for per-task copied assets")
    parser.add_argument("--quiet", action="store_true", help="Print only essential status")
    args = parser.parse_args()

    snapshot_path = Path(args.snapshot).resolve()
    screenshot_path = Path(args.screenshot).resolve()
    output_path = Path(args.output).resolve()
    text_output_path = Path(args.text_output).resolve()
    captures_dir = Path(args.captures_dir).resolve()

    text = read_text(snapshot_path)
    question = extract_question(text)
    if not question:
        raise SystemExit("Could not extract a question from the snapshot. This is likely not a question page.")

    options = extract_options(text)
    task_id = build_task_id(question, options)
    if task_id in load_existing_ids(output_path):
        if not args.quiet:
            print(f"Task already saved: {task_id}")
        return 0

    copied_snapshot = copy_capture(snapshot_path, captures_dir, task_id, ".md")
    copied_screenshot = copy_capture(screenshot_path, captures_dir, task_id, screenshot_path.suffix or ".png")

    record = TaskRecord(
        task_id=task_id,
        question=question,
        options=options,
        url=extract_url(text),
        title=extract_title(text),
        source_file=copied_snapshot or str(snapshot_path),
        screenshot_file=copied_screenshot,
        captured_at=datetime.now(timezone.utc).isoformat(),
    )
    append_jsonl(output_path, record)
    append_text_log(text_output_path, record)

    if not args.quiet:
        print(f"Saved task: {task_id}")
        print(question)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
