using System;
using System.Diagnostics;
using System.IO;
using System.Net.Sockets;
using System.Text.RegularExpressions;
using System.Threading;

namespace Greenify.Launcher
{
    class StartBackend
    {
        static void Main(string[] args)
        {
            Console.Title = "Greenify Backend Service Launcher";
            Console.OutputEncoding = System.Text.Encoding.UTF8;

            PrintHeader();

            string projectRoot = GetProjectRoot();
            string backendDir = Path.Combine(projectRoot, "backend");

            // 1. Locate Java JDK
            string javaExe = FindJavaExecutable();
            if (string.IsNullOrEmpty(javaExe))
            {
                PrintColor("[ERROR] Java Development Kit (JDK 17+) was not found!", ConsoleColor.Red);
                Console.WriteLine("Please install JDK 17 or set JAVA_HOME in your environment variables.");
                Console.WriteLine("\nPress any key to exit...");
                Console.ReadKey();
                return;
            }
            PrintColor("[✓] Java JDK detected: " + javaExe, ConsoleColor.Green);

            // 2. Clean stale processes listening on port 8080
            CleanPort(8080);

            // 3. Check MySQL Status
            CheckMySql();

            // 4. Verify & Download Dependencies / Build JAR if needed
            string targetJar = Path.Combine(backendDir, "target", "greenify-backend-1.0.0-SNAPSHOT.jar");
            if (!File.Exists(targetJar))
            {
                PrintColor("\n[*] Target JAR not found. Downloading dependencies & compiling Greenify backend...", ConsoleColor.Yellow);
                bool buildOk = BuildBackend(projectRoot, backendDir, javaExe);
                if (!buildOk || !File.Exists(targetJar))
                {
                    PrintColor("[ERROR] Maven build failed. Unable to create backend JAR.", ConsoleColor.Red);
                    Console.WriteLine("\nPress any key to exit...");
                    Console.ReadKey();
                    return;
                }
                PrintColor("[✓] Dependencies downloaded and project compiled successfully!\n", ConsoleColor.Green);
            }
            else
            {
                PrintColor("[✓] Backend package found: " + Path.GetFileName(targetJar), ConsoleColor.Green);
            }

            // 5. Ensure Environment Variables (GEMINI_API_KEY)
            SetupEnvironment();

            // 6. Launch Spring Boot Backend
            PrintColor("\n=======================================================", ConsoleColor.DarkGreen);
            PrintColor("  Starting Greenify Spring Boot Backend Service...", ConsoleColor.Green);
            PrintColor("  Base API:       http://localhost:8080/api/v1", ConsoleColor.Cyan);
            PrintColor("  IoT Simulator:  http://localhost:8080/api/v1/sim", ConsoleColor.Cyan);
            PrintColor("  Press Ctrl+C to terminate the backend at any time.", ConsoleColor.Gray);
            PrintColor("=======================================================\n", ConsoleColor.DarkGreen);

            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = javaExe;
            psi.Arguments = string.Format("-jar \"{0}\"", targetJar);
            psi.WorkingDirectory = projectRoot;
            psi.UseShellExecute = false;

            try
            {
                using (Process proc = Process.Start(psi))
                {
                    proc.WaitForExit();
                }
            }
            catch (Exception ex)
            {
                PrintColor("[ERROR] Error running backend: " + ex.Message, ConsoleColor.Red);
                Console.WriteLine("\nPress any key to exit...");
                Console.ReadKey();
            }
        }

        static void PrintHeader()
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine(@"
   ______                           _  __       
  / ____/________  ___  ____  (_) __/_  __ 
 / / __/ ___/ _ \/ _ \/ __ \/ / /_/ / / / / 
/ /_/ / /  /  __/  __/ / / / / __/ / /_/ /  
\____/_/   \___/\___/_/ /_/_/_/ /_/  \__, /   
     Smart Plastic Collection & Reward System
=======================================================");
            Console.ResetColor();
        }

        static string GetProjectRoot()
        {
            string current = AppDomain.CurrentDomain.BaseDirectory;
            if (Directory.Exists(Path.Combine(current, "backend")) && Directory.Exists(Path.Combine(current, "mobile")))
            {
                return current;
            }
            string parent = Path.GetDirectoryName(current.TrimEnd(Path.DirectorySeparatorChar));
            if (!string.IsNullOrEmpty(parent) && Directory.Exists(Path.Combine(parent, "backend")))
            {
                return parent;
            }
            return @"C:\Users\User\Desktop\Pendrive\Study Materials\Trimester 9\Aoop\Project\AOOP_Project-";
        }

        static string FindJavaExecutable()
        {
            string[] knownPaths = new string[]
            {
                @"C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot\bin\java.exe",
                Path.Combine(Environment.GetEnvironmentVariable("JAVA_HOME") ?? "", "bin", "java.exe"),
                @"C:\Program Files\Java\jdk-17\bin\java.exe",
                @"C:\Program Files\Eclipse Adoptium\jdk-17\bin\java.exe",
                @"C:\Program Files\Amazon Corretto\jdk17\bin\java.exe"
            };

            foreach (string p in knownPaths)
            {
                if (!string.IsNullOrEmpty(p) && File.Exists(p)) return p;
            }

            // Check system PATH
            string pathEnv = Environment.GetEnvironmentVariable("PATH") ?? "";
            foreach (string dir in pathEnv.Split(';'))
            {
                string candidate = Path.Combine(dir.Trim(), "java.exe");
                if (File.Exists(candidate)) return candidate;
            }

            return null;
        }

        static void CleanPort(int port)
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "netstat";
                psi.Arguments = "-ano -p tcp";
                psi.UseShellExecute = false;
                psi.RedirectStandardOutput = true;
                psi.CreateNoWindow = true;

                using (Process proc = Process.Start(psi))
                {
                    string output = proc.StandardOutput.ReadToEnd();
                    proc.WaitForExit();

                    string pattern = @":(" + port + @")\s+.*LISTENING\s+(\d+)";
                    Match match = Regex.Match(output, pattern);
                    if (match.Success)
                    {
                        string pid = match.Groups[2].Value;
                        PrintColor(string.Format("[!] Port {0} is held by PID {1}. Reclaiming port...", port, pid), ConsoleColor.Yellow);
                        Process.Start(new ProcessStartInfo
                        {
                            FileName = "taskkill",
                            Arguments = "/F /PID " + pid,
                            UseShellExecute = false,
                            CreateNoWindow = true
                        }).WaitForExit();
                        Thread.Sleep(800);
                        PrintColor(string.Format("[✓] Port {0} successfully reclaimed.", port), ConsoleColor.Green);
                        return;
                    }
                }
                PrintColor(string.Format("[✓] Port {0} is available.", port), ConsoleColor.Green);
            }
            catch (Exception)
            {
                PrintColor(string.Format("[i] Port {0} verified.", port), ConsoleColor.Gray);
            }
        }

        static void CheckMySql()
        {
            if (IsPortListening(3306))
            {
                PrintColor("[✓] MySQL Database is active on port 3306.", ConsoleColor.Green);
                return;
            }

            // Attempt to auto-start XAMPP MySQL
            string xamppMysql = @"C:\xampp\mysql\bin\mysqld.exe";
            string xamppIni = @"C:\xampp\mysql\bin\my.ini";
            if (File.Exists(xamppMysql) && File.Exists(xamppIni))
            {
                PrintColor("[*] Port 3306 is inactive. Starting XAMPP MySQL automatically...", ConsoleColor.Yellow);
                try
                {
                    ProcessStartInfo psi = new ProcessStartInfo();
                    psi.FileName = xamppMysql;
                    psi.Arguments = "--defaults-file=\"" + xamppIni + "\" --standalone";
                    psi.WorkingDirectory = @"C:\xampp";
                    psi.UseShellExecute = false;
                    psi.CreateNoWindow = true;
                    Process.Start(psi);

                    // Wait up to 5 seconds for MySQL to bind to port 3306
                    for (int i = 0; i < 10; i++)
                    {
                        Thread.Sleep(500);
                        if (IsPortListening(3306))
                        {
                            PrintColor("[✓] XAMPP MySQL started successfully on port 3306!", ConsoleColor.Green);
                            return;
                        }
                    }
                }
                catch (Exception ex)
                {
                    PrintColor("[WARN] Failed to auto-start MySQL: " + ex.Message, ConsoleColor.DarkYellow);
                }
            }

            PrintColor("[!] MySQL port 3306 is not currently responding.", ConsoleColor.Yellow);
            PrintColor("    Tip: If you use XAMPP, open XAMPP Control Panel and start MySQL.", ConsoleColor.DarkYellow);
        }

        static bool IsPortListening(int port)
        {
            try
            {
                using (TcpClient tcp = new TcpClient())
                {
                    IAsyncResult ar = tcp.BeginConnect("127.0.0.1", port, null, null);
                    bool ok = ar.AsyncWaitHandle.WaitOne(1000);
                    if (ok && tcp.Connected)
                    {
                        tcp.EndConnect(ar);
                        return true;
                    }
                }
            }
            catch { }
            return false;
        }

        static bool BuildBackend(string projectRoot, string backendDir, string javaExe)
        {
            string mvnExe = @"C:\tools\apache-maven-3.9.6\bin\mvn.cmd";
            if (!File.Exists(mvnExe))
            {
                string mvnw = Path.Combine(backendDir, "mvnw.cmd");
                if (File.Exists(mvnw)) mvnExe = mvnw;
                else mvnExe = "mvn";
            }

            string javaHome = Path.GetDirectoryName(Path.GetDirectoryName(javaExe));

            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = mvnExe;
            psi.Arguments = "clean package -DskipTests";
            psi.WorkingDirectory = backendDir;
            psi.UseShellExecute = false;
            psi.EnvironmentVariables["JAVA_HOME"] = javaHome;

            try
            {
                using (Process proc = Process.Start(psi))
                {
                    proc.WaitForExit();
                    return proc.ExitCode == 0;
                }
            }
            catch (Exception ex)
            {
                PrintColor("[ERROR] Maven execution error: " + ex.Message, ConsoleColor.Red);
                return false;
            }
        }

        static void SetupEnvironment()
        {
            string key = Environment.GetEnvironmentVariable("GEMINI_API_KEY");
            if (string.IsNullOrEmpty(key))
            {
                string userKey = Environment.GetEnvironmentVariable("GEMINI_API_KEY", EnvironmentVariableTarget.User);
                if (!string.IsNullOrEmpty(userKey))
                {
                    Environment.SetEnvironmentVariable("GEMINI_API_KEY", userKey);
                }
            }
        }

        static void PrintColor(string msg, ConsoleColor color)
        {
            Console.ForegroundColor = color;
            Console.WriteLine(msg);
            Console.ResetColor();
        }
    }
}
