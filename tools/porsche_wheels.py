"""Build a staggered set of centre-lock GT wheels. Blender X is the axle axis."""
import math

import bpy


def _material(name, color, metallic, roughness):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = mat.diffuse_color
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return mat


def build_wheels(front_y, rear_y, front_track, rear_track, front_radius=.345,
                 rear_radius=.36, front_width=.275, rear_width=.335):
    """Create separate tire, rim, rotor and caliper meshes for the Godot rig."""
    rubber = _material("GT road rubber", (.017, .020, .023), .02, .76)
    rotor = _material("Carbon ceramic brake rotor", (.21, .22, .22), .65, .45)
    alloy = _material("Satin titanium forged alloy", (.37, .40, .43), .88, .26)
    shadow = _material("Wheel recess graphite", (.027, .032, .037), .68, .41)
    gold = _material("Ceramic brake ochre", (.94, .46, .018), .35, .30)
    for y, track, radius, width in [(front_y, front_track, front_radius, front_width),
                                   (rear_y, rear_track, rear_radius, rear_width)]:
        for side in (-1, 1):
            origin = (side * track / 2, y, radius)

            def mesh(name, vertices, faces, mat, smooth=False):
                data = bpy.data.meshes.new(name)
                points = [(side * x, ly, z) for x, ly, z in vertices]
                data.from_pydata(points, [], faces if side > 0 else [f[::-1] for f in faces])
                data.update()
                obj = bpy.data.objects.new(name, data)
                bpy.context.collection.objects.link(obj)
                obj.location = origin
                data.materials.append(mat)
                for polygon in data.polygons:
                    polygon.use_smooth = smooth
                return obj

            def lathe(name, profile, mat, steps=72, sweep=math.tau, offset=0):
                count = steps if sweep == math.tau else steps + 1
                vertices = []
                faces = []
                for i in range(count):
                    a = offset + sweep * i / steps
                    vertices.extend((x, r * math.cos(a), r * math.sin(a)) for x, r in profile)
                n = len(profile)
                for i in range(steps):
                    for j in range(n):
                        k = (j + 1) % n
                        h = (i + 1) % count
                        faces.append((i*n+j, h*n+j, h*n+k, i*n+k))
                if count > steps:
                    faces.extend([tuple(range(n-1, -1, -1)), tuple(range(steps*n, count*n))])
                return mesh(name, vertices, faces, mat, True)

            half = width / 2
            rim = radius * .762
            # The outer profile includes four recessed circumferential tread channels.
            profile = [(-half*.86, rim*.96), (-half, radius*.89), (-half*.93, radius*.96),
                       (-half*.76, radius*.993)]
            for lane in (-.53, -.19, .19, .53):
                profile.extend([((lane+dx)*half, radius*frac) for dx, frac in
                                [(-.035,1), (-.026,.984), (.026,.984), (.035,1)]])
            profile.extend([(half*.76,radius*.993), (half*.96,radius*.96),
                            (half,radius*.89), (half*.88,rim*.96)])
            lathe("Performance tire GT", profile, rubber)
            lathe("Diamond cut rim GT", [(-half*.72,rim*.93), (-half*.71,rim),
                  (half*.90,rim), (half*.97,rim*.975), (half*.97,rim*.947),
                  (half*.83,rim*.93)], alloy)
            face = half * .48
            lathe("Brake disc GT", [(face-.022,rim*.35),(face-.022,rim*.85),
                  (face,rim*.85),(face,rim*.35)], rotor)
            lathe("Red brake caliper GT ceramic", [(face-.035,rim*.66),(face-.036,rim*.91),
                  (face+.026,rim*.92),(face+.034,rim*.83),(face+.024,rim*.69)],
                  gold, 16, math.radians(65), math.radians(-33))
            vertices, faces = [], []
            for i in range(10):
                angle = math.tau*i/10
                for fork in (-1,1):
                    # A dished spoke splits into two slender arms at the rim.
                    outline = [(.19,0,.078,.64), (.56,.022,.041,.72),
                               (.74,fork*.063,.033,.82), (.957,fork*.105,.027,.91)]
                    base = len(vertices)
                    for r, twist, spread, depth in outline:
                        for dx, lateral in [(0,-spread),(0,spread),(-.022,spread),(-.022,-spread)]:
                            a = angle+twist+lateral
                            vertices.append((half*depth+dx, rim*r*math.cos(a), rim*r*math.sin(a)))
                    for row in range(3):
                        for j in range(4):
                            k = (j+1)%4
                            faces.append((base+4*row+j,base+4*row+k,base+4*row+4+k,base+4*row+4+j))
            mesh("Alloy wheel GT split spokes", vertices, [f[::-1] for f in faces], alloy)
            lathe("Wheel hub GT centre lock", [(half*.46,.001),(half*.46,rim*.24),
                  (half*.72,rim*.225),(half*.81,rim*.15),(half*.81,.001)], shadow, 12)
            lathe("Centre cap GT metal lip", [(half*.795,rim*.154),(half*.825,rim*.154),
                  (half*.825,rim*.143),(half*.795,rim*.143)], alloy,48)
            marks, holes = [], []
            for row in range(3):
                for i in range(28):
                    angle = math.tau*(i+row*.32)/28
                    bore_y = rim*(.54+row*.105)*math.cos(angle)
                    bore_z = rim*(.54+row*.105)*math.sin(angle)
                    start = len(marks)
                    for j in range(7):
                        phi = math.tau*j/7
                        marks.append((face+.0006, bore_y+.0032*math.cos(phi),
                                      bore_z+.0032*math.sin(phi)))
                    holes.append(tuple(range(start,start+7)))
            mesh("Brake disc GT drilled ports", marks, holes, shadow)
            # Fixed links sit behind each wheel and remain attached to the chassis.
            links, link_faces = [], []
            inner_hub = -half + .008
            for vertical, radius_link in [(-.115,.018), (.105,.013)]:
                for attachment in [-.16,.14]:
                    outboard = (inner_hub, 0, vertical)
                    inboard = (inner_hub-.22, attachment, vertical+.035)
                    dx, dy, dz = (b-a for a,b in zip(outboard,inboard))
                    horizontal = math.hypot(dx,dy)
                    u = (-dy/horizontal, dx/horizontal, 0)
                    length = math.sqrt(horizontal**2+dz**2)
                    v = (-dz*u[1]/length, dz*u[0]/length, horizontal/length)
                    base = len(links)
                    for point in [outboard,inboard]:
                        for j in range(8):
                            a = math.tau*j/8
                            links.append(tuple(point[k]+radius_link*(u[k]*math.cos(a)+v[k]*math.sin(a))
                                               for k in range(3)))
                    for j in range(8):
                        k = (j+1)%8
                        link_faces.append((base+j,base+k,base+8+k,base+8+j))
            mesh("GT suspension wishbones", links, link_faces, shadow, True)
