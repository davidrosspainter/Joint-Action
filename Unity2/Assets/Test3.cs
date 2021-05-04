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

public class Test3 : MonoBehaviour
{

    List<Vector2> targetPositions = new List<Vector2>() { new Vector2(269.8443f, 111.7732f),
                                                          new Vector2(111.7732f, 269.8443f),
                                                          new Vector2(-111.7732f, 269.8443f),
                                                          new Vector2(-269.8443f, 111.7732f),
                                                          new Vector2(-269.8443f, -111.7732f),
                                                          new Vector2(-111.7732f, -269.8443f),
                                                          new Vector2(+111.7732f, -269.8443f),
                                                          new Vector2(269.8443f, -111.7732f)};

    List<Color> colors = new List<Color> { new Color(0.5f, 0.25f, 0.6f, 1),
                                           new Color(1, 0, 1, 1),
                                           new Color(1, 0, 0, 1),
                                           new Color(1, 0.36f, 0, 1),
                                           new Color(1, 1, 0, 1),
                                           new Color(0, 1, 0, 1),
                                           new Color(0, 1, 1, 1),
                                           new Color(0, 0, 1, 1)};

    TextMeshProUGUI FPS_text;

    public static class Number
    {
        static public int axes = 2;
        static public int frames = 360;
        static public int trials = 480;
        static public int cursors = 3;
        static public int targetPositions = 8;
        static public int control = 2;
    }

    class Sizes
    {
        public static float target = 76.9231f;
        public static float cursor = 15;
        public static float gaze = 36.0902f;
    }

    float[] xMod = new float[2] { -1080 / 2, +1080 / 2 };

    Material cursorMaterial;

    class Cursor
    {
        public GameObject gameObject;
        public List<Vector2> trajectory = new List<Vector2>();

        public Cursor(GameObject gameObject, List<Vector2> trajectory)
        {
            this.gameObject = gameObject;
            this.trajectory = trajectory;
        }
    }

    List<Cursor> cursors = new List<Cursor>();

    class Ports
    {
        public static int[] P1 = new int[2] { 1000, 1001 };
        public static int[] P2 = new int[2] { 1002, 1003 };
        public static int target_positions_solo = 1004;
        public static int[] P1_gaze_solo = new int[2] { 1005, 1006 };
        public static int[] P2_gaze_solo = new int[2] { 1007, 1008 };
    }

    int FRAME = 0;

    void Start()
    {

        Stopwatch sw = new Stopwatch();
        sw.Start();

        // scene setup

        FPS_text = GameObject.Find("Canvas/FPS_text").GetComponent<TextMeshProUGUI>();
        cursorMaterial = Resources.Load("UnlitColor") as Material;

        GameObject P1 = new GameObject(name: "P1");
        GameObject P2 = new GameObject(name: "P2");
        GameObject targets = new GameObject(name: "targets");
        GameObject P1_gaze_solo = new GameObject(name: "P1_gaze_solo");
        GameObject P2_gaze_solo = new GameObject(name:"P2_gaze_solo");

        // add target positions

        for (int TARGET = 0; TARGET < Number.targetPositions; TARGET++)
        {
            GameObject target = Create.Polygon(position: new Vector3(targetPositions[TARGET].x, 0, targetPositions[TARGET].y),
                                               rotation: new Vector3(-90, 0, 0),
                                               radius: Sizes.target,
                                               edgeThickness: .1f,
                                               nSegments: Defaults.nSegementsCircle,
                                               color: Color.white, //colors[TARGET],
                                               sortingOrder: 2);
            
            target.name = "target." + TARGET.ToString();
            target.transform.parent = targets.transform;
        }

        // session setup

        float[,] target_positions = GetBufferData(Ports.target_positions_solo);
        printArrayDimensions(target_positions);

        float[,] GetBufferData(int port)
        {
            UnityBuffer unityBuffer = new UnityBuffer();

            if (unityBuffer.connect(host: "127.0.0.1", port: port))
            {
                print("connected");
                unityBuffer.header = unityBuffer.getHeader();
                float[,] data = unityBuffer.getFloatData(0, unityBuffer.header.nSamples - 1);
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

        // reshape method
        List<Vector2> reshapeTrajectory(List<float[,]> trajectoryData, int TRIAL)
        {
            List<Vector2> trajectoryToUse = new List<Vector2>();

            for (int FRAME = 0; FRAME < Number.frames; FRAME++)
            {
                Vector2 position = new Vector2();

                for (int AXIS = 0; AXIS < Number.axes; AXIS++)
                {
                    //print(TRIAL.ToString() + ":" + FRAME.ToString() + ":" + AXIS.ToString());
                    position[AXIS] = trajectoryData[AXIS][TRIAL, FRAME];
                }
                trajectoryToUse.Add(position);
            }

            return trajectoryToUse;
        }

        void AddCursors(int[] ports, GameObject parent, CursorType cursorType){

            // get trajectories

            List<float[,]> trajectory = new List<float[,]>();

            foreach (var port in ports)
            {
                print(port);
                trajectory.Add(GetBufferData(port));
                printArrayDimensions(trajectory[trajectory.Count - 1]);
            }

            // build cursors

            for (int TRIAL = 0; TRIAL < Number.trials; TRIAL++)
            {
                List<Vector2> cursorTrajectory = reshapeTrajectory(trajectory, TRIAL);

                Color colorToUse = colors[(int)target_positions[TRIAL, 0] - 1];

                //float randomValue = Random.Range(.25f, 1);
                //colorToUse.r = colorToUse.r * randomValue;
                //colorToUse.g = colorToUse.g * randomValue;
                //colorToUse.b = colorToUse.b * randomValue;

                GameObject SpawnCursorObject()
                {
                    switch (cursorType)
                    {
                        case CursorType.cursor:
                            GameObject cursorObject1 = PlaneObject.Create(width: Sizes.cursor,
                                                              length: Sizes.cursor,
                                                              widthSegments: 1,
                                                              lengthSegments: 1).gameObject;

                            cursorObject1.GetComponent<Renderer>().material = cursorMaterial;
                            cursorObject1.GetComponent<Renderer>().material.color = colorToUse;
                            return cursorObject1;
                        case CursorType.gaze:
                            GameObject cursorObject2 = Create.Polygon(position: Vector3.zero,
                                                          rotation: new Vector3(-90, 0, 0),
                                                          radius: Sizes.gaze,
                                                          edgeThickness: .1f,
                                                          nSegments: Defaults.nSegementsCircle,
                                                          color: colorToUse,
                                                          sortingOrder: 1);
                            return cursorObject2;
                        default:
                            return new GameObject();
                    }
                }

                GameObject cursorObject = SpawnCursorObject();
                cursorObject.name = "cursor." + TRIAL.ToString();
                cursorObject.transform.parent = parent.transform;

                cursors.Add(new Cursor(gameObject: cursorObject, trajectory: cursorTrajectory));
            }
        }

        AddCursors(Ports.P1, P1, CursorType.cursor);
        AddCursors(Ports.P2, P2, CursorType.cursor);

        AddCursors(Ports.P1_gaze_solo, P1_gaze_solo, CursorType.gaze);
        AddCursors(Ports.P2_gaze_solo, P2_gaze_solo, CursorType.gaze);

        print(sw.Elapsed.Seconds);

    }

    enum CursorType
    {
        cursor,
        gaze
    }

    void Update()
    {

        if (FRAME == Number.frames)
        {
            FRAME = 0;
        }

        foreach (var cursor in cursors)
        {
            if (!float.IsNaN(cursor.trajectory[FRAME].x) && !float.IsNaN(cursor.trajectory[FRAME].y))
            {
                cursor.gameObject.transform.position = new Vector3(cursor.trajectory[FRAME].x, 0, cursor.trajectory[FRAME].y);
            }
        }

        FRAME++;

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


