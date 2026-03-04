WIDTH = 120
HEIGHT = 100

grid = [["#" for _ in range(WIDTH)] for _ in range(HEIGHT)]


def carve_room(x, y, w, h, tile="."):
    for iy in range(y, y + h):
        for ix in range(x, x + w):
            grid[iy][ix] = tile


def carve_corridor(x1, y1, x2, y2, width=6):
    if x1 == x2:
        for y in range(min(y1, y2), max(y1, y2)):
            for w in range(width):
                grid[y][x1 + w] = "."
    elif y1 == y2:
        for x in range(min(x1, x2), max(x1, x2)):
            for w in range(width):
                grid[y1 + w][x] = "."


def label(x, y, char):
    grid[y][x] = char


# -------------------------
# Sector Rooms (~30–40 tiles)
# -------------------------

# COMMAND CENTER
carve_room(43, 30, 34, 34)
label(60, 47, "C")

# DEFENSE GRID
carve_room(43, 2, 34, 32)
label(60, 15, "T")

# COMMS
carve_room(5, 30, 32, 32)
label(20, 45, "M")

# ARCHIVE
carve_room(85, 30, 30, 30)
label(100, 45, "A")

# STORAGE
carve_room(5, 65, 34, 30)
label(20, 80, "S")

# POWER
carve_room(43, 65, 34, 32)
label(60, 80, "P")

# FABRICATION
carve_room(85, 65, 32, 32)
label(100, 80, "F")

# HANGAR
carve_room(40, 75, 40, 20)
label(60, 85, "H")

# GATEWAY
carve_room(50, 95, 20, 5)
label(60, 97, "G")

# -------------------------
# Corridors
# -------------------------

# Command to Defense
carve_corridor(60, 30, 60, 20)

# Command to Comms
carve_corridor(43, 47, 30, 47)

# Command to Archive
carve_corridor(77, 47, 85, 47)

# Command to Power
carve_corridor(60, 64, 60, 65)

# Power to Storage
carve_corridor(43, 80, 39, 80)

# Power to Fabrication
carve_corridor(77, 80, 85, 80)

# Power to Hangar
carve_corridor(60, 97, 60, 75)

# Hangar to Gateway
carve_corridor(60, 95, 60, 100)


# -------------------------
# Write map file
# -------------------------

with open("tutorial_v1.map", "w") as f:
    f.write(f"WIDTH {WIDTH}\n")
    f.write(f"HEIGHT {HEIGHT}\n\n")

    for row in grid:
        f.write("".join(row) + "\n")

print("tutorial_v1.map generated")
