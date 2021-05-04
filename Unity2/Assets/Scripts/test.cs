using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Diagnostics;
using RealtimeBuffer;
using System.Linq;

public class test : MonoBehaviour
{

    public static class Number
    {
        static public int axes = 2;
        static public int frames = 360;
        static public int trials = 480;
        static public int cursors = 3;
    }

    Material cursorMaterial;

    class Cursor
    {
        public GameObject gameObject;
        public float[,] trajectory = new float[Number.frames, Number.axes];

        public Cursor(GameObject gameObject, float[,] trajectory) {
            this.gameObject = gameObject;
            this.trajectory = trajectory;
        }
    }

    List<Cursor> cursors = new List<Cursor>();

    static int[] ports = Enumerable.Range(1000, 10).ToArray();
    int nPorts = ports.Length;

    // Start is called before the first frame update
    void Start()
    {

        cursorMaterial = Resources.Load("unlitColor") as Material;

        float[,] GetBufferData(int port)
        {
            UnityBuffer unityBuffer = new UnityBuffer();

            if (unityBuffer.connect(host: "127.0.0.1", port: port))
            {
                print("connected");
                unityBuffer.header = unityBuffer.getHeader();

                float[,] data = unityBuffer.getFloatData(0, unityBuffer.header.nSamples - 1);

                print(data.GetLength(0));
                print(data.GetLength(1));

                return data;
            }
            else
            {
                print("connection failed...");
                return new float[0, 0];
            }
        }

        foreach (var port in ports)
        {
            print(port);
            cursors.Add(new Cursor(gameObject: GameObject.CreatePrimitive(PrimitiveType.Plane), trajectory: GetBufferData(port)));

            print(cursors[cursors.Count - 1].trajectory.GetLength(0));
            print(cursors[cursors.Count - 1].trajectory.GetLength(1));



            cursors[cursors.Count-1].gameObject.transform.localScale = new Vector3(.1f, .1f, .1f) * 15;
            cursors[cursors.Count-1].gameObject.GetComponent<Renderer>().material = cursorMaterial;
        }
    }

    int frame = 0;

    // Update is called once per frame
    void Update()
    {
        
        if(frame == Number.frames)
        {
            frame = 0;
        }

        foreach (var cursor in cursors)
        {
            cursor.gameObject.transform.position = new Vector3(cursor.trajectory[frame, 0], 0, cursor.trajectory[frame, 1]);
        }
        frame++;
    }

}
