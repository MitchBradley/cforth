/*
 * Converts a .obj file into a float buffer for OpenGL
 *
 * Reads stdin looking for lines like:
 *	# Vertices: N
 *	# Faces: M
 *      v X Y Z r g b
 *      f i0/t0/x0 i1/t1/x1 i2/t2/x2
 *
 * Writes out a file of binary float data
 *      float faces[N][3]
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#define DEFAULT_SIZE 1000000

void make_room(void **mem)
{
	if (*mem == NULL) {
		*mem = malloc(DEFAULT_SIZE);
	}
}

struct xyz { float x; float y; float z; };
struct ixyz { int x; int y; int z; };

void normalize (struct xyz *v)
{
    // calculate the length of the vector
    float len = (float)(sqrt((v->x * v->x) + (v->y * v->y) + (v->z * v->z)));

    // avoid division by 0
    if (len == 0.0f)
        return;

    // reduce to unit size
    v->x /= len;
    v->y /= len;
    v->z /= len;
}

// normal() - returns a unit normal vector
void normal (struct xyz v[3], struct xyz *normal)
{
    struct xyz a, b;

    // calculate the vectors A and B
    // note that v[3] is defined with counterclockwise winding in mind
    // a
    a.x = v[0].x - v[1].x;
    a.y = v[0].y - v[1].y;
    a.z = v[0].z - v[1].z;
    // b
    b.x = v[1].x - v[2].x;
    b.y = v[1].y - v[2].y;
    b.z = v[1].z - v[2].z;

    // calculate the cross product and place the resulting vector
    // into the address specified by vertex_t *normal
    normal->x = (a.y * b.z) - (a.z * b.y);
    normal->y = (a.z * b.x) - (a.x * b.z);
    normal->z = (a.x * b.y) - (a.y * b.x);

    // normalize to length 1
    normalize(normal);
}

int main(argc, argv)
	int argc;
	char *argv[];
{
	FILE *ffile  = fopen("faces.bin", "w");
	FILE *vnfile = fopen("vertex_normals.bin", "w");
	FILE *fnfile = fopen("face_normals.bin",   "w");
	FILE *vifile = fopen("vertex_indices.bin", "w");
	FILE *nifile = fopen("normal_indices.bin", "w");
	FILE *vfile  = fopen("vertices.bin", "w");
	FILE *nfile  = fopen("normals.bin", "w");

        struct xyz *vertices = NULL;
        struct xyz *normals = NULL;
        struct xyz *colors = NULL;
	struct xyz *faces = NULL;
	struct xyz *face_normals = NULL;
	struct xyz *vertex_normals = NULL;
	struct ixyz *vertex_indices = NULL;
	struct ixyz *normal_indices = NULL;

	int num_vertices = 0;
	int vertexno = 0;
	int normalno = 0;

	int num_faces = 0;
	int faceno = 0;

        int i0, i1, i2, t0, t1, t2, n0, n1, n2;

	char linebuf[256];
	while (!feof(stdin) && fgets(linebuf, 256, stdin)) {
		int n;
		if (linebuf[strlen(linebuf)-1] == '\n') {
			linebuf[strlen(linebuf)-1] = '\0';
		}

		if (strncmp(linebuf, "o ", 2) && num_vertices == 0) {
			make_room((void **)&vertices);
			make_room((void **)&normals);
			make_room((void **)&colors);
			make_room((void **)&faces);

			make_room((void **)&face_normals);
			make_room((void **)&vertex_normals);

			make_room((void **)&vertex_indices);
			make_room((void **)&normal_indices);
		}

		n = sscanf(linebuf, "# Vertices: %d", &num_vertices);
                if (n == 1) {
			printf("Vertices %d\n", num_vertices);
			vertices = (struct xyz *)calloc(num_vertices, sizeof(*vertices));
			colors   = (struct xyz *)calloc(num_vertices, sizeof(*colors));
			normals  = (struct xyz *)calloc(num_vertices, sizeof(*normals));
			continue;
                }

		n = sscanf(linebuf, "# Faces: %d", &num_faces);
                if (n == 1) {
			printf("Faces %d\n", num_faces);
			faces = (struct xyz *)calloc(num_faces * 3, sizeof(*faces));
			face_normals   = (struct  xyz *)calloc(num_faces*3, sizeof(*face_normals));
			vertex_normals = (struct  xyz *)calloc(num_faces*3, sizeof(*vertex_normals));
			vertex_indices = (struct ixyz *)calloc(num_faces, sizeof(*vertex_indices));
			normal_indices = (struct ixyz *)calloc(num_faces, sizeof(*normal_indices));
			continue;
                }

		n = sscanf(linebuf, "v %f %f %f %f %f %f",
			   &vertices[vertexno].x, &vertices[vertexno].y, &vertices[vertexno].z,
			   &colors[vertexno].x, &colors[vertexno].y, &colors[vertexno].z);
                if (n == 3 || n == 6) {
			vertexno++;
			continue;
                }

		n = sscanf(linebuf, "vn %f %f %f", &normals[normalno].x, &normals[normalno].y, &normals[normalno].z);
                if (n == 3) {
			normalno++;
		}

		n = sscanf(linebuf, "f %d//%d %d//%d %d//%d", &i0, &n0, &i1, &n1, &i2, &n2);
                if (n == 6) {
			i0--; i1--; i2--; n0--; n1--; n2--;
			vertex_indices[faceno] = (struct ixyz) { i0, i1, i2 };
			normal_indices[faceno] = (struct ixyz) { n0, n1, n2 };
			faces[3*faceno+0] = vertices[i0];
			faces[3*faceno+1] = vertices[i1];
			faces[3*faceno+2] = vertices[i2];
			vertex_normals[3*faceno+0] = normals[n0];
			vertex_normals[3*faceno+1] = normals[n1];
			vertex_normals[3*faceno+2] = normals[n2];
			normal(&faces[3*faceno], &face_normals[3*faceno]);
			face_normals[3*faceno+2] = face_normals[3*faceno+1] = face_normals[3*faceno];
			faceno++;
			continue;
                }

		n = sscanf(linebuf, "f %d/%d/%d %d/%d/%d %d/%d/%d", &i0, &t0, &n0, &i1, &t1, &n1, &i2, &t2, &n2);
                if (n == 9) {
			i0--; i1--; i2--; n0--; n1--; n2--;
			vertex_indices[faceno] = (struct ixyz) { i0, i1, i2 };
			normal_indices[faceno] = (struct ixyz) { n0, n1, n2 };
			faces[3*faceno+0] = vertices[i0];
			faces[3*faceno+1] = vertices[i1];
			faces[3*faceno+2] = vertices[i2];
			face_normals[3*faceno+0] = normals[n0];
			face_normals[3*faceno+1] = normals[n1];
			face_normals[3*faceno+2] = normals[n2];
			faceno++;
			continue;
                }
        }
        fwrite(vertices,       sizeof(*vertices),        vertexno, vfile);   fclose(vfile);
        fwrite(normals,        sizeof(*normals),         normalno, nfile);   fclose(nfile);
        fwrite(faces,          sizeof(*faces),           faceno*3, ffile);   fclose(ffile);
        fwrite(vertex_normals, sizeof(*vertex_normals),  faceno*3, vnfile);  fclose(vnfile);
        fwrite(face_normals,   sizeof(*face_normals),    faceno*3, fnfile);  fclose(fnfile);
        fwrite(normal_indices, sizeof(*normal_indices),  faceno,   nifile);  fclose(nifile);
        fwrite(vertex_indices, sizeof(*vertex_indices),  faceno,   vifile);  fclose(vifile);

	return(0);
}
