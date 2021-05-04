using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using PrimitivesPro.Primitives;
using PrimitivesPro.GameObjects;

namespace Graphics
{

    public class Defaults
    {
        public static int nSegementsCircle = 90;
        public class SortingOrder
        {
            public static int controlPoint = 1;
            public static int triangle = 0;

            public static int back = -32768;
            public static int front = +32767;
        }
    }

    public class Create : MonoBehaviour
    {
        static public GameObject Polygon(Vector3 position, Vector3 rotation, float radius, float edgeThickness, int nSegments, Color color, int sortingOrder) // symmetrical
        {
            // edgeThickness value is in proportion of radius units (1 = filled, < 1 = empty/outline)

            float baseRadius = 0.5f;

            GameObject go = new GameObject("polygon");
            go.AddComponent<MeshFilter>();

            Renderer renderer = go.AddComponent<MeshRenderer>();
            //renderer.material = new Material(Shader.Find("Unlit/Color"));
            renderer.material = Resources.Load("UnlitColor") as Material;
            renderer.material.color = color;
            renderer.sortingOrder = sortingOrder;

            Ring ring = go.AddComponent<Ring>();
            ring.GenerateGeometry(baseRadius, baseRadius - baseRadius*edgeThickness, nSegments); // if borderwidth == radius: filled, else: empty

            go.transform.Rotate(-90, 0, 0, Space.Self); go.transform.Rotate(0, 0, 180, Space.Self); // rotate to standard 2D perspective

            go.transform.position = position;
            go.transform.Rotate(rotation.x, rotation.y, rotation.z, Space.Self); // new Vector3(0, 180, 0) - upside down

            

            switch (nSegments) // scale
            {
                case 4: // square
                    float s = (radius) / Mathf.Sqrt(2); // length of side
                    go.transform.localScale *= radius*(radius/s);
                    print(radius);
                    print(s);
                    break;

                default: // circle
                    go.transform.localScale *= radius;
                    break;

            }

            return go;
        }

        static public GameObject Cross(Vector3 position, float radius, float edgeThickness, Color color, int sortingOrder)
        {
            // edgeThickness value is in proportion of length (1 = square < 1 = rectangle)

            GameObject parent = new GameObject("cross");

            float[] rotation = new float[2] { -45, 45 };

            for (int i = 0; i < 2; i++)
            {
                var go = new GameObject("plane." + i.ToString());
                go.AddComponent<MeshFilter>();
                Renderer renderer = go.AddComponent<MeshRenderer>();
                renderer.material = new Material(Shader.Find("Unlit/Color"));
                renderer.material.color = color;
                renderer.sortingOrder = sortingOrder;

                var plane = go.AddComponent<PlaneObject>();
                plane.GenerateGeometry(edgeThickness/2, 1, 1, 1);

                go.transform.Rotate(-90, 0, 0, Space.Self); //go.transform.Rotate(0, 0, 180, Space.Self); // rotate to standard 2D perspective
                go.transform.Rotate(0, rotation[i], 0, Space.Self); // new Vector3(0, 180, 0) - upside down

                go.transform.parent = parent.transform;
            }

            parent.transform.position = position;
            parent.transform.localScale *= radius;
            return parent;
        }
        //static public GameObject ControlPoint(Vector3 position, float radius, float width, Color color, int sortingOrder)
        //{
        //    GameObject go = new GameObject("controlPoint");
        //    GameObject polygon = Polygon(Vector3.zero, Vector3.zero, radius, width, Defaults.nSegementsCircle, color, sortingOrder);
        //    GameObject cross = Cross(Vector3.zero, radius, width, color, sortingOrder);

        //    polygon.transform.parent = go.transform;
        //    cross.transform.parent = go.transform;

        //    go.transform.position = position;
        //    return go;
        //}


        static public GameObject ControlPoint(Vector3 position, float radius, float width, Color color, int sortingOrder)
        {
            GameObject go = new GameObject("controlPoint");
            GameObject polygon = Polygon(Vector3.zero, Vector3.zero, radius, width, Defaults.nSegementsCircle, color, sortingOrder);
            GameObject cross = Cross(Vector3.zero, radius, width, color, sortingOrder);

            GameObject collider = Collider(radius, 8);

            polygon.transform.parent = go.transform;
            cross.transform.parent = go.transform;
            collider.transform.parent = go.transform;

            go.transform.position = position;
            return go;
        }

        static public GameObject Collider(float radius, int segments)
        {
            var go = new GameObject("collider");
            MeshCollider meshc = go.AddComponent(typeof(MeshCollider)) as MeshCollider;
            meshc.sharedMesh = new Mesh();
            var mesh = meshc.sharedMesh;
            float GenerationTimeMS = EllipsePrimitive.GenerateGeometry(mesh, radius / 2, radius / 2, segments);

            //go.AddComponent<MeshFilter>().sharedMesh = mesh;
            //go.AddComponent<MeshRenderer>();
            //go.GetComponent<Renderer>().sharedMaterial = new Material(Shader.Find("Diffuse"));

            go.transform.Rotate(-90, 0, 0, Space.Self); //go.transform.Rotate(0, 0, 180, Space.Self); // rotate to standard 2D perspective
            return go;
        }

    }






}
