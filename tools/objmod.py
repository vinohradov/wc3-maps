"""Dump a WC3 object-modification file (w3a/w3u/w3t/w3d/...) — 1.26 format.
  uv run python tools/objmod.py <file.w3a> [id ...]
"""
import struct
import sys


class Reader:
    def __init__(self, data):
        self.data, self.pos = data, 0

    def i32(self):
        v = struct.unpack_from("<i", self.data, self.pos)[0]
        self.pos += 4
        return v

    def f32(self):
        v = struct.unpack_from("<f", self.data, self.pos)[0]
        self.pos += 4
        return round(v, 4)

    def raw4(self):
        v = self.data[self.pos:self.pos + 4]
        if len(v) < 4:
            raise ValueError("eof")
        self.pos += 4
        return v.decode("latin-1")

    def cstr(self):
        end = self.data.index(b"\0", self.pos)
        v = self.data[self.pos:end].decode("utf-8", "replace")
        self.pos = end + 1
        return v


def parse(data, levels):
    """-> (version, [(table, orig_id, new_id, [(field, level, value)])]); stops quietly on a truncated tail."""
    r = Reader(data)
    version, objs = r.i32(), []
    try:
        for table in ("original", "custom"):
            for _ in range(r.i32()):
                orig, new, mods = r.raw4(), r.raw4(), []
                objs.append((table, orig, new, mods))
                for _ in range(r.i32()):
                    field, t, lvl = r.raw4(), r.i32(), 0
                    if levels:
                        lvl, _ptr = r.i32(), r.i32()
                    val = r.i32() if t == 0 else r.f32() if t in (1, 2) else r.cstr()
                    r.raw4()  # end marker
                    mods.append((field, lvl, val))
    except (struct.error, ValueError):
        pass  # protected maps often have a truncated tail
    return version, objs


if __name__ == "__main__":
    path = sys.argv[1]
    _, objs = parse(open(path, "rb").read(), path.endswith((".w3a", ".w3d", ".w3q")))
    want = set(sys.argv[2:])
    for table, orig, new, mods in objs:
        oid = new if new.strip("\0") else orig
        if want and oid not in want and orig not in want:
            continue
        print(f"[{oid}] base={orig} ({table})")
        for field, lvl, val in mods:
            print(f"   {field} L{lvl} = {val!r}")
