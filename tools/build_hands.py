"""Generate the shared right-hand meshes in Godot's Y-up coordinate system."""
from math import cos, sin, tau
from pathlib import Path


def build_hand(gripping):
    vertices, faces = [], []

    def loft(sections):
        first = len(vertices) + 1
        sides = 12
        for x, y, z, width, depth in sections:
            for step in range(sides):
                angle = tau * step / sides
                vertices.append((x + width*cos(angle), y, z + depth*sin(angle)))
        for row in range(len(sections)-1):
            for step in range(sides):
                a = first + row*sides + step
                b = first + row*sides + (step+1)%sides
                faces.append((a,b,b+sides,a+sides))
        faces.append(tuple(range(first+sides-1,first-1,-1)))
        faces.append(tuple(range(first+(len(sections)-1)*sides,first+len(sections)*sides)))

    # Palm faces the thigh. Separate knuckles place the index toward the front.
    loft([(0,.069,0,.015,.022),(0,.046,0,.023,.031),
          (0,.018,0,.025,.040),(0,-.009,.002,.020,.039),
          (0,-.019,.004,.014,.034)])
    for z, length, radius in [(-.026,.054,.010),(-.007,.061,.011),
                              (.013,.055,.010),(.031,.043,.008)]:
        curl = .038 if gripping else .013
        loft([(0,-.007,z,radius,radius),(.002,-.023,z,radius,radius),
              (-curl*.32,-.017-length*.62,z,radius*.89,radius*.91),
              (-curl,-.016-length,z-.002,radius*.68,radius*.72),
              (-curl-.002,-.018-length,z-.002,.002,.003)])
    loft([(-.004,.032,-.026,.015,.014),(-.012,.017,-.038,.014,.014),
          (-.022,.002,-.044,.012,.012),(-.029,-.014,-.040,.009,.010),
          (-.031,-.020,-.037,.004,.005)])
    name = 'GrippingHand' if gripping else 'RelaxedHand'
    target = Path(__file__).resolve().parents[1] / 'characters' / (name+'.obj')
    with target.open('w') as out:
        out.write('o '+name+'\ns 1\n')
        for point in vertices:
            out.write('v %.6f %.6f %.6f\n' % point)
        for face in faces:
            out.write('f '+' '.join(map(str,face))+'\n')


if __name__ == '__main__':
    for pose in (False, True):
        build_hand(pose)
