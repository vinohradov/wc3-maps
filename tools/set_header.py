"""Set the map name in the 512-byte HM3W header (the name shown in the game's map list on 1.26).
  uv run python tools/set_header.py <map.w3x> "<name>"
Header: 'HM3W', int32 0, name\\0, int32 flags, int32 max players, zero padding to 512 bytes.
"""
import struct
import sys

path, name = sys.argv[1], sys.argv[2]
data = bytearray(open(path, "rb").read())
assert data[:4] == b"HM3W", "not a w3x/w3m file"
end = data.index(b"\0", 8)
flags, players = struct.unpack_from("<ii", data, end + 1)
header = b"HM3W" + b"\0" * 4 + name.encode("utf-8") + b"\0" + struct.pack("<ii", flags, players)
assert len(header) <= 512, "name too long"
data[:512] = header + b"\0" * (512 - len(header))
open(path, "wb").write(data)
print(f"{path}: header name = {name!r} (flags {flags:#x}, {players} players)")
