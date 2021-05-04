using System.Collections.Generic;
using UnityEngine;
using RealtimeBuffer;



public class NetCode2 : MonoBehaviour {


    // ---- needs to be on same drive as program ---- need to recode otherwise

    public static bool isFlush = true;
    public static bool isGameRunning = true; // true until quit for thread shutdown
    public static string localIP;

    public enum BID
    {
        //status_unity
    }

    static public List<BufferD> buffer = new List<BufferD>();

    private void Start()
    {
        StartNetworkXXX();
    }

    string networkPath = @"D:\Network.Buffer.DRP.19.07.20\";
    

    public void StartNetworkXXX()
    {

        Path path = new Path(networkPath);

        print(path.network);
        print(path.realtimeHack);
        print(path.fileName);

        localIP = GetLocalIP();

        //buffer.Add(new BufferD(name:"status", host:localIP, port:Test7.Ports.status_unity, isHosted:true, nChans:1, nScans:1, path: path));
    }


    public static string GetLocalIP()
    {
        using (System.Net.Sockets.Socket socket = new System.Net.Sockets.Socket(System.Net.Sockets.AddressFamily.InterNetwork, System.Net.Sockets.SocketType.Dgram, 0))
        {
            socket.Connect("8.8.8.8", 65530);
            System.Net.IPEndPoint endPoint = socket.LocalEndPoint as System.Net.IPEndPoint;
            return endPoint.Address.ToString();
        }
    }


    public class Path
    {
        public string network;
        public string realtimeHack;
        public string fileName;

        public Path(string network)
        {
            this.network = network;
            this.realtimeHack = this.network + "realtimeHack.10.11.17\\";
            this.fileName = this.network + "IsBufferRunning\\IsBufferRunning\\bin\\Debug\\IsBufferRunning.exe";
        }
    }

    public class BufferD // my first class!
    {
        
        public string name;
        public string host;
        public int port;

        public int nChans;
        public int nScans;

        public bool isHosted; // true = if local, false if remote
        public bool isRunning = false;

        public UnityBuffer socket = new UnityBuffer();
        public Header hdr;

        public Path path;

        public BufferD(string name, string host, int port, bool isHosted, int nChans, int nScans, Path path)
        {
            this.name = name;
            this.host = host;
            this.port = port;

            print(this.host + ": " + this.port.ToString() + ": " + this.name);

            this.isHosted = isHosted;
            this.nChans = nChans;
            this.nScans = nScans;

            this.path = path;

            this.isRunning = CheckIsRunning(this.path);

            if (this.isHosted)
            {
                if (!this.isRunning)
                {
                    Start(this.path);
                }

                if (isFlush)
                {
                    Flush();
                }
            }

        }


        public bool CheckIsRunning(Path path)
        {
            bool isBufferRunning = false;
            var proc = new System.Diagnostics.Process
            {
                StartInfo = new System.Diagnostics.ProcessStartInfo // get process by window name - super dodge - also cannot run Pathly from unity
                {
                    FileName = path.fileName,
                    Arguments = this.host + " " + this.port,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    CreateNoWindow = true
                }
            };

            proc.Start();

            string line = "";

            while (!proc.StandardOutput.EndOfStream)
            {
                line = proc.StandardOutput.ReadLine();
            }

            if (line == "False")
            {
                isBufferRunning = false;
            }
            else if (line == "True")
            {
                isBufferRunning = true;
            }
            else
            {
                isBufferRunning = false;
            }
            return isBufferRunning;
        }


        public void Start(Path path)
        {
            print("attempting start...");
            string cmdTest = "/k cd " + path.realtimeHack + " & buffer.exe " + this.host + " " + this.port + " -&";
            System.Diagnostics.Process.Start("CMD.exe", cmdTest);

            if (this.socket.connect(this.host, this.port))
            {
                try
                {
                    // ----- populate header (necessary if hosted)
                    this.hdr = this.socket.getHeader();
                    this.hdr.nChans = this.nChans;
                    this.hdr.dataType = DataType.FLOAT32;
                    this.socket.putHeader(this.hdr);
                    this.isRunning = true;
                }
                catch (System.Net.Sockets.SocketException) { }
                this.socket.disconnect();
                this.isRunning = false;
            }
        }

        public void Flush()
        {
            if (this.socket.connect(this.host, this.port))
            {
                try
                {
                    this.socket.flushData();
                }
                catch (System.Net.Sockets.SocketException) { }
                this.socket.disconnect();
            }
        }


    }


    void OnApplicationQuit()
    {
        isGameRunning = false; // end buffer monitor threads
    }


    static public void PutDataThread(int idx, float[,] dataToPut)
    {
        new System.Threading.Thread(() => // Create a new Thread
        {
            PutData(idx, dataToPut);
        }).Start(); // Start the Thread
    }

    static public void PutDataThread2(BufferD buffer, float[,] dataToPut)
    {
        new System.Threading.Thread(() => // Create a new Thread
        {
            if (buffer.socket.connect(buffer.host, buffer.port))
            {
                buffer.socket.putData(dataToPut);
                //buffer[idx].socket.disconnect();
            }
        }).Start(); // Start the Thread
    }



    static public void PutData(int idx, float[,] dataToPut)
    {
        if (buffer[idx].socket.connect(buffer[idx].host, buffer[idx].port))
        {
            buffer[idx].socket.putData(dataToPut);
            //buffer[idx].socket.disconnect();
        }
    }


}