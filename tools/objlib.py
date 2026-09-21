"""Minimal read/modify/write for the map's SLK tables and INI-style txt files.

SLK: rows keyed by column 1 (object id). clone() copies a row under a new id, set() writes one cell;
untouched lines stay byte-identical. Txt: [id] sections with key=value lines.
"""
import re
from pathlib import Path

UNITS = Path(__file__).resolve().parent.parent / "src" / "map" / "Units"


def _fmt(v):
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, (int, float)):
        return repr(v) if isinstance(v, float) else str(v)
    return '"' + str(v) + '"'


class Slk:
    def __init__(self, name):
        self.path = UNITS / name
        raw = self.path.read_bytes()
        self.eol = "\r\n" if b"\r\n" in raw else "\n"
        self.lines = raw.decode("latin-1").split(self.eol)
        self._index()

    def _index(self):
        self.cells = {}  # (y, x) -> line index
        self.rows = {}  # id -> y
        self.header = {}  # column name -> x
        y = None
        for i, line in enumerate(self.lines):
            if not line.startswith("C;"):
                continue
            m = re.search(r";Y(\d+)", line)
            if m:
                y = int(m.group(1))
            x = re.search(r";X(\d+)", line)
            if not x:
                continue
            x = int(x.group(1))
            self.cells[(y, x)] = i
            k = re.search(r";K(.*)$", line)
            val = k.group(1).strip('"') if k else None
            if y == 1:
                self.header[val] = x
            elif x == 1:
                self.rows[val] = y

    def get(self, oid, col):
        i = self.cells.get((self.rows[oid], self.header[col]))
        if i is None:
            return None
        k = re.search(r";K(.*)$", self.lines[i])
        return k.group(1).strip('"') if k else None

    def set(self, oid, col, value):
        y, x = self.rows[oid], self.header[col]
        i = self.cells.get((y, x))
        if i is not None:
            self.lines[i] = re.sub(r";K.*$", lambda _m: ";K" + _fmt(value), self.lines[i])
        else:
            last = max(li for (cy, _), li in self.cells.items() if cy == y)
            self.lines.insert(last + 1, f"C;X{x};K{_fmt(value)}")
            self._index()

    def clone(self, src, new):
        """Copy row src as new (appended). No-op if new already exists."""
        if new in self.rows:
            return False
        sy = self.rows[src]
        ny = max(self.rows.values()) + 1
        src_cells = sorted((x, li) for (cy, x), li in self.cells.items() if cy == sy)
        out = []
        for x, li in src_cells:
            k = re.search(r";K(.*)$", self.lines[li])
            val = _fmt(new) if x == 1 else (k.group(1) if k else '""')
            out.append((f"C;Y{ny};X{x};K{val}" if x == 1 else f"C;X{x};K{val}"))
        end = max(i for i, l in enumerate(self.lines) if l.strip() == "E")
        self.lines[end:end] = out
        for i, l in enumerate(self.lines):  # bounds record: B;Y<rows>;X<cols>;D0 0 <rows-1> <cols-1>
            if l.startswith("B;"):
                ys = int(re.search(r"Y(\d+)", l).group(1))
                xs = int(re.search(r"X(\d+)", l).group(1))
                ys = max(ys, ny)
                self.lines[i] = re.sub(r"Y\d+", f"Y{ys}", l)
                self.lines[i] = re.sub(r";D.*$", f";D0 0 {ys - 1} {xs - 1}", self.lines[i])
        self._index()
        return True

    def save(self):
        self.path.write_bytes(self.eol.join(self.lines).encode("latin-1"))


class Txt:
    def __init__(self, name):
        self.path = UNITS / name
        if not self.path.exists():
            self.path.write_bytes(b"")
        raw = self.path.read_bytes()
        self.bom = raw.startswith(b"\xef\xbb\xbf")
        text = raw.decode("utf-8-sig")
        self.eol = "\r\n" if "\r\n" in text else "\n"
        self.lines = text.split(self.eol)

    def _section(self, oid):
        start = next((i for i, l in enumerate(self.lines) if l.strip() == f"[{oid}]"), None)
        if start is None:
            return None, None
        end = next((i for i in range(start + 1, len(self.lines)) if self.lines[i].startswith("[")), len(self.lines))
        return start, end

    def clone(self, src, new):
        if self._section(new)[0] is not None:
            return False
        s, e = self._section(src)
        body = [l for l in self.lines[s + 1:e] if l.strip()]
        while self.lines and not self.lines[-1].strip():
            self.lines.pop()
        self.lines += [f"[{new}]"] + body + [""]
        return True

    def set(self, oid, key, value):
        s, e = self._section(oid)
        for i in range(s + 1, e):
            if self.lines[i].split("=", 1)[0] == key:
                self.lines[i] = f"{key}={value}"
                return
        self.lines.insert(s + 1, f"{key}={value}")

    def save(self):
        data = self.eol.join(self.lines).encode("utf-8")
        self.path.write_bytes((b"\xef\xbb\xbf" if self.bom else b"") + data)


def _is_new_id(oid):
    return oid[:2] in ("h9", "A9")


def move_new_sections(src, dst):
    """Move every [h9xx]/[A9xx] section from Txt src into Txt dst (replacing dst's copy)."""
    out, moved, i = [], {}, 0
    lines = src.lines
    while i < len(lines):
        m = re.match(r"\[(\w{4})\]", lines[i])
        if m and _is_new_id(m.group(1)):
            j = i + 1
            while j < len(lines) and not lines[j].startswith("["):
                j += 1
            moved[m.group(1)] = [l for l in lines[i:j] if l.strip()]
            i = j
            continue
        out.append(lines[i])
        i += 1
    src.lines = out
    keep = []
    i = 0
    while i < len(dst.lines):  # drop dst's stale copies of moved sections
        m = re.match(r"\[(\w{4})\]", dst.lines[i])
        if m and m.group(1) in moved:
            i += 1
            while i < len(dst.lines) and not dst.lines[i].startswith("["):
                i += 1
            continue
        keep.append(dst.lines[i])
        i += 1
    while keep and not keep[-1].strip():
        keep.pop()
    for sec in moved.values():
        keep += sec
    dst.lines = keep + [""]
    return len(moved)
