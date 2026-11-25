"""Generate the shared right-hand meshes in Godot's Y-up coordinate system."""
from math import cos, sin, tau
from pathlib import Path


def build_hand(gripping, running=False):
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
        if gripping:
            curl = .038
            loft([(0,-.007,z,radius,radius),(.002,-.023,z,radius,radius),
                  (-curl*.32,-.017-length*.62,z,radius*.89,radius*.91),
                  (-curl,-.016-length,z-.002,radius*.68,radius*.72),
                  (-curl-.002,-.018-length,z-.002,.002,.003)])
            continue
        spread = z * (.03 if running else .10)
        curl = .032 + (z+.026)*.23 if running else .010 + (z+.026)*.16
        if running:
            length *= .72
        loft([(0,-.007,z,radius,radius),
              (.002,-.023,z,radius*1.04,radius),
              (-curl*.22,-.015-length*.48,z+spread,radius*.86,radius*.89),
              (-curl*.45,-.015-length*.65,z+spread,radius*.91,radius*.90),
              (-curl*.80,-.015-length*.86,z+spread,radius*.73,radius*.79),
              (-curl,-.016-length,z+spread,radius*.54,radius*.61),
              (-curl-.001,-.018-length,z+spread,.002,.003)])
    loft([(-.004,.032,-.026,.015,.014),(-.012,.017,-.038,.014,.014),
          (-.022,.002,-.044,.012,.012),(-.029,-.014,-.040,.009,.010),
          (-.031,-.020,-.037,.004,.005)])
    name = 'GrippingHand' if gripping else ('RunningHand' if running else 'RelaxedHand')
    target = Path(__file__).resolve().parents[1] / 'characters' / (name+'.obj')
    with target.open('w') as out:
        out.write('o '+name+'\ns 1\n')
        for point in vertices:
            out.write('v %.6f %.6f %.6f\n' % point)
        for face in faces:
            out.write('f '+' '.join(map(str,face))+'\n')


if __name__ == '__main__':
    build_hand(False)
    build_hand(True)
    build_hand(False, running=True)
