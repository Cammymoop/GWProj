extends ConvexPolygonShape3D

# A helper resource to generate rectangular prism collision shapes with beveled edges.

# the size of the box along each axis
@export var size: Vector3 = Vector3(1, 1, 1):
	set(new_size):
		size = new_size
		regenerate_vertices()

@export_range(0.0, 1.0, 0.01)
var bevel_amount: float = 0.1:
	set(new_amount):
		var new_radius = new_amount * (min(size.x, size.y, size.z)/2.0)
		bevel_amount = new_radius
		regenerate_vertices()


func regenerate_vertices() -> void:
		var vertices: PackedVector3Array = PackedVector3Array()

		# generate the vertices for the box
		# 3 for each corner, moved inwards along each face by the bevel radius
		var bevel_radius = bevel_amount * (min(size.x, size.y, size.z)/2.0)

		for x in [-1, 1]:
			for y in [-1, 1]:
				for z in [-1, 1]:
					var X = x * (size.x/2.0)
					var Y = y * (size.y/2.0)
					var Z = z * (size.z/2.0)
					vertices.append(Vector3(X - bevel_radius*x, Y - bevel_radius*y, Z))
					vertices.append(Vector3(X - bevel_radius*x, Y , Z - bevel_radius*z))
					vertices.append(Vector3(X, Y - bevel_radius*y, Z - bevel_radius*z))
		points = vertices
