using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Diagnostics;
using RealtimeBuffer;
using System.Linq;
using TMPro;
using Graphics;
using PrimitivesPro.Primitives;
using PrimitivesPro.GameObjects;

public class Test2 : MonoBehaviour
{

    List<Vector2> targetPositions = new List<Vector2>() { new Vector2(269.8443f, 111.7732f),
                                                          new Vector2(111.7732f, 269.8443f),
                                                          new Vector2(-111.7732f, 269.8443f),
                                                          new Vector2(-269.8443f, 111.7732f),
                                                          new Vector2(-269.8443f, -111.7732f),
                                                          new Vector2(-111.7732f, -269.8443f),
                                                          new Vector2(+111.7732f, -269.8443f),
                                                          new Vector2(269.8443f, -111.7732f)};

    public TextMeshProUGUI FPS_text;

    public static class Number
    {
        static public int axes = 2;
        static public int frames = 360;
        static public int trials = 480;
        static public int cursors = 3;
        static public int targetPositions = 8;
    }

    Material cursorMaterial;

    class Cursor
    {
        public GameObject gameObject;
        public float[,] trajectory = new float[Number.frames, Number.axes];

        public Cursor(GameObject gameObject, float[,] trajectory)
        {
            this.gameObject = gameObject;
            this.trajectory = trajectory;
        }
    }

    List<Cursor> cursors = new List<Cursor>();

    static int[] ports = new int[2] { 1000, 1001 }; // Enumerable.Range(1000, 2).ToArray();
    int nPorts = ports.Length;

    List<Color> colors = new List<Color> { new Color(0.5f, 0.25f, 0.6f, 1),
                                           new Color(1, 0, 1, 1),
                                           new Color(1, 0, 0, 1),
                                           new Color(1, 0.36f, 0, 1),
                                           new Color(1, 1, 0, 1),
                                           new Color(0, 1, 0, 1),
                                           new Color(0, 1, 1, 1),
                                           new Color(0, 0, 1, 1)};

    void Start()
    {
        FPS_text = GameObject.Find("Canvas/FPS").GetComponent<TextMeshProUGUI>();

        Stopwatch sw = new Stopwatch();
        sw.Start();

        cursorMaterial = Resources.Load("UnlitColor") as Material;

        float[,] GetBufferData(int port)
        {
            UnityBuffer unityBuffer = new UnityBuffer();

            if (unityBuffer.connect(host: "127.0.0.1", port: port))
            {
                print("connected");
                unityBuffer.header = unityBuffer.getHeader();

                float[,] data = unityBuffer.getFloatData(0, unityBuffer.header.nSamples - 1);

                //print(data.GetLength(0));
                //print(data.GetLength(1));

                return data;
            }
            else
            {
                print("connection failed...");
                return new float[0, 0];
            }
        }

        void printArrayDimensions(float[,] array)
        {
            print(array.GetLength(0));
            print(array.GetLength(1));
        }

        // get trajectories

        List<float[,]> trajectory = new List<float[,]>();

        foreach (var port in ports)
        {
            print(port);
            trajectory.Add(GetBufferData(port));
            printArrayDimensions(trajectory[trajectory.Count - 1]);
        }

        // get colors

        float[,] target_positions = GetBufferData(1002);
        printArrayDimensions(target_positions);


        // build cursors

        for (int TRIAL = 0; TRIAL < Number.trials; TRIAL++)
        {

            // reshape

            float[,] trajectory_to_use = new float[Number.frames, Number.axes];

            for (int FRAME = 0; FRAME < Number.frames; FRAME++)
                {
                for (int AXIS = 0; AXIS < Number.axes; AXIS++)
                {
                    //print(TRIAL.ToString() + ":" + FRAME.ToString() + ":" + AXIS.ToString());
                    trajectory_to_use[FRAME, AXIS] = trajectory[AXIS][TRIAL, FRAME];
                }
            }


            Color colorToUse = colors[(int)target_positions[TRIAL, 0] - 1];
            float randomValue = Random.Range(.25f, 1);
            colorToUse.r = colorToUse.r * randomValue;
            colorToUse.g = colorToUse.g * randomValue;
            colorToUse.b = colorToUse.b * randomValue;


            PlaneObject cursorPlane = PlaneObject.Create(width: Sizes.cursor,
                                                         length: Sizes.cursor,
                                                         widthSegments: 1,
                                                         lengthSegments: 1);

            cursorPlane.gameObject.GetComponent<Renderer>().material = cursorMaterial;
            cursorPlane.gameObject.GetComponent<Renderer>().material.color = colorToUse;

            cursors.Add(new Cursor(gameObject: cursorPlane.gameObject, trajectory: trajectory_to_use));

            //cursors[cursors.Count - 1].gameObject.transform.localScale = new Vector3(.1f, .1f, .1f) * 15;
            //cursors[cursors.Count - 1].gameObject.GetComponent<Renderer>().material = cursorMaterial;
            //cursors[cursors.Count - 1].gameObject.GetComponent<Renderer>().material.color = colorToUse;
        }



        // add target positions

        for (int TARGET = 0; TARGET < Number.targetPositions; TARGET++)
        {
            
            GameObject target = Create.Polygon(position: new Vector3(targetPositions[TARGET].x, 0, targetPositions[TARGET].y),
                                               rotation: new Vector3(-90,0,0),
                                               radius: Sizes.target,
                                               edgeThickness: .1f,
                                               nSegments: Defaults.nSegementsCircle,
                                               color: Color.white, //colors[TARGET],
                                               sortingOrder: 2);

            //GameObject target = GameObject.CreatePrimitive(PrimitiveType.Plane);
            //target.transform.localScale = new Vector3(.1f, .1f, .1f) * 15;
            //target.transform.position = new Vector3(targetPositions[TARGET].x, 0, targetPositions[TARGET].y);
            //target.GetComponent<Renderer>().material = cursorMaterial;
            //target.GetComponent<Renderer>().material.color = colors[TARGET];

            target.name = TARGET.ToString();
        }
    
        print(sw.Elapsed.Seconds);

    }

    class Sizes
    {
        public static float target = 76.9231f;
        public static float cursor = 15;
    }


    int frame = 0;

    void Update()
    {
        
        if (frame == Number.frames)
        {
            frame = 0;
        }

        foreach (var cursor in cursors)
        {
            if (!float.IsNaN(cursor.trajectory[frame, 0]) && !float.IsNaN(cursor.trajectory[frame, 1]))
            {
                cursor.gameObject.transform.position = new Vector3(cursor.trajectory[frame, 0], 0, cursor.trajectory[frame, 1]);
            }
        }

        frame++;

        // FPS

        if (Time.unscaledTime > FPS_timer)
        {
            int fps = (int)(1f / Time.unscaledDeltaTime);
            FPS_text.text = "FPS: " + fps;
            FPS_timer = Time.unscaledTime + FPS_refreshRate;
        }
    }

    float FPS_refreshRate = 1f;
    float FPS_timer;

}

//public static class ExtensionMethods
//{
//    public static IEnumerable<T> SliceRow<T>(this T[,] array, int row)
//    {
//        for (var i = 0; i < array.GetLength(0); i++)
//        {
//            yield return array[i, row];
//        }
//    }

//    public static T[] column<T>(this T[,] multidimArray, int wanted_column)
//    {
//        int l = multidimArray.GetLength(0);
//        T[] columnArray = new T[l];
//        for (int i = 0; i < l; i++)
//        {
//            columnArray[i] = multidimArray[i, wanted_column];
//        }
//        return columnArray;
//    }

//    public static T[] row<T>(this T[,] multidimArray, int wanted_row)
//    {
//        int l = multidimArray.GetLength(1);
//        T[] rowArray = new T[l];
//        for (int i = 0; i < l; i++)
//        {
//            rowArray[i] = multidimArray[wanted_row, i];
//        }
//        return rowArray;
//    }

//}


