# Obj2HolyC

Converts OBJ files to HolyC data-structures. Supports edges (lines), triangles (faces) and a mostly untested Object mode.

# Notes

Make sure your models are appropriately scaled. 1 obj unit = 1 screen pixel @ Z==0. The floating point positions of the vertices are cast to integers on export. You can always scale them down as your last matrix transformation if you need more detail.

# Blender Export Settings

Disable everything, normals, materials, UVs, etc. You can use "Triangulate Faces" if applicable.

## 2D Orthographic Style

 * Facing right while in "Front Orthographic" perspective in blender
 * +Z Forward
 * -Y Up
