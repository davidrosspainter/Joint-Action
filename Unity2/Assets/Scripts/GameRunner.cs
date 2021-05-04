using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Graphics;

public class GameRunner : MonoBehaviour
{

    int setSize = 36;

    static Vector2 fieldSize = new Vector2(512, 512);
    static float shipSize = 50 * (1 / 1.4f) * 2;

    public class Asteroid
    {
        public static float size = shipSize;

        public static float minStartingEccentricity = 71.4286f;

        public static Vector2 min = new Vector2(size/2 - fieldSize.x, size/2 - fieldSize.y);
        public static Vector2 max = new Vector2(fieldSize.x - size/2, fieldSize.y - size/2);

        public static float speed = 180;

        public class Valence
        {
            static public int positive = 0;
            static public int negative = 1;
            static public int neutral = 2;
        }

        public class PolygonState
        {
            public const int empty = 0;
            public const int filled = 1;
        }

    }

    float damageMultiplier = 10;

    public class AST
    {
        public Vector2 pos;
        public float angle;
        public Vector2 inc;

        public float radius;

        public int polygonState = Asteroid.PolygonState.empty;

        public GameObject parent = new GameObject("asteroid");
        public GameObject polygonEmpty;
        public GameObject polygonFilled;

        public Color color;
        public int valence;

        public void Initialise(int v, Color c)
        {
            valence = v;
            color = c;

            polygonEmpty = Create.Polygon(Vector3.zero, new Vector3(0, 45, 0), Asteroid.size, .2f, Defaults.nSegementsCircle, color, 2);
            polygonFilled = Create.Polygon(Vector3.zero, new Vector3(0, 45, 0), Asteroid.size, 1, Defaults.nSegementsCircle, color, 2);

            polygonEmpty.transform.parent = parent.transform;
            polygonFilled.transform.parent = parent.transform;

            angle = Random.Range(0, 2 * Mathf.PI);
            //radius = Random.Range(Asteroid.minStartingEccentricity, fieldSize.x-shipSize/2);

            //pos.x = Mathf.Cos(angle) * radius;
            //pos.y = Mathf.Sin(angle) * radius;

            while (true)
            {
                pos.x = Random.Range(-fieldSize.x + shipSize / 2, +fieldSize.x - shipSize / 2);
                pos.y = Random.Range(-fieldSize.y + shipSize / 2, +fieldSize.y - shipSize / 2);

                if (Mathf.Sqrt(Mathf.Pow(pos.x, 2) + Mathf.Pow(pos.y, 2)) > Asteroid.minStartingEccentricity) // minimum radius from starting pos 
                {
                    break;
                }
            }

            parent.transform.position = new Vector3(pos.x, pos.y, 0);

            SetState();

        }

        public void Update()
        {

            inc.x = Mathf.Cos(angle) * Time.deltaTime * Asteroid.speed;
            inc.y = Mathf.Sin(angle) * Time.deltaTime * Asteroid.speed;

            pos.x = pos.x + inc.x;
            pos.y = pos.y + inc.y;

            //if (Mathf.Sqrt(Mathf.Pow(pos.x, 2) + Mathf.Pow(pos.y, 2)) >= fieldSize.x) // minimum radius from starting pos 
            //{
            //    pos *= -1;
            //}

            if (pos.x < Asteroid.min.x || pos.x > Asteroid.max.x)
            {
                if (pos.x < Asteroid.min.x)
                    pos.x = Asteroid.max.x;
                else
                    pos.x = Asteroid.min.x;
            }

            if (pos.y < Asteroid.min.y || pos.y > Asteroid.max.y)
            {
                if (pos.y < Asteroid.min.y)
                    pos.y = Asteroid.max.y;
                else
                    pos.y = Asteroid.min.y;
            }

            parent.transform.position = new Vector3(pos.x, pos.y, 0);

            SetState();
        }

        void SetState()
        {
            switch (polygonState)
            {
                case Asteroid.PolygonState.empty:
                    polygonEmpty.SetActive(true);
                    polygonFilled.SetActive(false);
                    break;
                case Asteroid.PolygonState.filled:
                    polygonEmpty.SetActive(false);
                    polygonFilled.SetActive(true);
                    break;
            }
        }

    }


    List<AST> ast = new List<AST>();
    GameObject field;

    // Start is called before the first frame update
    void Start()
    {

          Random.InitState(0);

        //field = Create.Polygon(Vector3.zero, new Vector3(0, 45, 0), fieldSize.x*2, 1, 4, Color.white, 2);

        field = Create.Polygon(Vector3.zero, new Vector3(0, 45, 0), fieldSize.x * 2, .01f, 90, Color.white, 2);
        GameObject field2 = Create.Polygon(Vector3.zero, new Vector3(0, 45, 0), fieldSize.x * 2, .01f, 4, Color.white, 2);
        GameObject field3 = Create.Polygon(Vector3.zero, new Vector3(0, 45, 0), fieldSize.x * 2, .01f, 3, Color.white, 2);

        field.name = "field";

        for (int i = 0; i < setSize; i++)
        {
            ast.Add(new AST());
            if (i<setSize*1/3)
                ast[i].Initialise(Asteroid.Valence.positive, Color.red);
            else if (i<setSize*2/3)
                ast[i].Initialise(Asteroid.Valence.negative, Color.green);
            else
                ast[i].Initialise(Asteroid.Valence.neutral, Color.blue);
        }
        Extensions.Shuffle(ast); // randomise draw order
    }

    // Update is called once per frame
    void Update()
    {
        foreach (var a in ast)
        {
            a.Update();
        }



    }


    
    

}


public static class Extensions
{
    public static void Shuffle<T>(this IList<T> list)
    {
        System.Security.Cryptography.RNGCryptoServiceProvider provider = new System.Security.Cryptography.RNGCryptoServiceProvider();
        int n = list.Count;
        while (n > 1)
        {
            byte[] box = new byte[1];
            do provider.GetBytes(box);
            while (!(box[0] < n * (System.Byte.MaxValue / n)));
            int k = (box[0] % n);
            n--;
            T value = list[k];
            list[k] = list[n];
            list[n] = value;
        }
    }
}
