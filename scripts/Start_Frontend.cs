using System;
using System.Diagnostics;
using System.IO;
using System.Threading;

namespace Greenify.Launcher
{
    class StartFrontend
    {
        static void Main(string[] args)
        {
            Console.Title = "Greenify Mobile & Web App Launcher";
            Console.OutputEncoding = System.Text.Encoding.UTF8;

            PrintHeader();

            string projectRoot = GetProjectRoot();
            string mobileDir = Path.Combine(projectRoot, "mobile");

            // 1. Locate Flutter Executable
            string flutterExe = FindFlutterExecutable();
            if (string.IsNullOrEmpty(flutterExe))
            {
                PrintColor("[ERROR] Flutter SDK was not found on your system!", ConsoleColor.Red);
                Console.WriteLine("Please ensure Flutter is installed and added to your PATH environment variable.");
                Console.WriteLine("\nPress any key to exit...");
                Console.ReadKey();
                return;
            }
            PrintColor("[✓] Flutter SDK detected: " + flutterExe, ConsoleColor.Green);

            // 2. Check and Download Missing Dependencies (flutter pub get)
            PrintColor("\n[*] Verifying and downloading Flutter dependencies (flutter pub get)...", ConsoleColor.Yellow);
            bool depsOk = RunFlutterPubGet(mobileDir, flutterExe);
            if (!depsOk)
            {
                PrintColor("[WARN] 'flutter pub get' completed with warnings. Attempting to proceed...", ConsoleColor.DarkYellow);
            }
            else
            {
                PrintColor("[✓] All Flutter dependencies and assets are up-to-date!", ConsoleColor.Green);
            }

            // 3. Device Selection (Chrome / Windows / Edge)
            string targetDevice = "chrome";
            if (args != null && args.Length > 0 && !string.IsNullOrEmpty(args[0]))
            {
                targetDevice = args[0].ToLower().Trim();
            }
            else
            {
                PrintColor("\nAvailable Target Platforms:", ConsoleColor.Cyan);
                Console.WriteLine("  [1] Google Chrome (Web - Recommended)");
                Console.WriteLine("  [2] Windows Desktop Application");
                Console.WriteLine("  [3] Microsoft Edge (Web)");
                Console.Write("\nSelect target [1-3] (Default is Chrome in 5s): ");

                int countdown = 5;
                bool selected = false;
                while (countdown > 0)
                {
                    if (Console.KeyAvailable)
                    {
                        var key = Console.ReadKey(true);
                        if (key.KeyChar == '2') targetDevice = "windows";
                        else if (key.KeyChar == '3') targetDevice = "edge";
                        else targetDevice = "chrome";
                        selected = true;
                        break;
                    }
                    Thread.Sleep(1000);
                    countdown--;
                }
                if (!selected)
                {
                    Console.WriteLine("\n[Auto-selected: Google Chrome]");
                    targetDevice = "chrome";
                }
                else
                {
                    Console.WriteLine("\n[Selected: " + targetDevice + "]");
                }
            }

            // 4. Launch Application
            PrintColor("\n=======================================================", ConsoleColor.DarkGreen);
            PrintColor(string.Format("  Starting Greenify Application on {0}...", targetDevice.ToUpper()), ConsoleColor.Green);
            PrintColor("  (Hot reload: press 'r' | Hot restart: press 'R' | Quit: 'q')", ConsoleColor.Cyan);
            PrintColor("=======================================================\n", ConsoleColor.DarkGreen);

            string launchArgs = "run -d " + targetDevice;
            if (targetDevice == "chrome" || targetDevice == "edge")
            {
                launchArgs += " --web-port 3000";
            }

            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = flutterExe;
            psi.Arguments = launchArgs;
            psi.WorkingDirectory = mobileDir;
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
                PrintColor("[ERROR] Error starting Flutter app: " + ex.Message, ConsoleColor.Red);
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
         Citizen, Recycler & Admin UI Portal
=======================================================");
            Console.ResetColor();
        }

        static string GetProjectRoot()
        {
            string current = AppDomain.CurrentDomain.BaseDirectory;
            if (Directory.Exists(Path.Combine(current, "mobile")) && Directory.Exists(Path.Combine(current, "backend")))
            {
                return current;
            }
            string parent = Path.GetDirectoryName(current.TrimEnd(Path.DirectorySeparatorChar));
            if (!string.IsNullOrEmpty(parent) && Directory.Exists(Path.Combine(parent, "mobile")))
            {
                return parent;
            }
            return @"C:\Users\User\Desktop\Pendrive\Study Materials\Trimester 9\Aoop\Project\AOOP_Project-";
        }

        static string FindFlutterExecutable()
        {
            string[] knownPaths = new string[]
            {
                @"C:\Users\User\develop\flutter\bin\flutter.bat",
                @"C:\flutter\bin\flutter.bat",
                @"C:\src\flutter\bin\flutter.bat",
                @"D:\flutter\bin\flutter.bat"
            };

            foreach (string p in knownPaths)
            {
                if (!string.IsNullOrEmpty(p) && File.Exists(p)) return p;
            }

            // Check system PATH
            string pathEnv = Environment.GetEnvironmentVariable("PATH") ?? "";
            foreach (string dir in pathEnv.Split(';'))
            {
                string candidate = Path.Combine(dir.Trim(), "flutter.bat");
                if (File.Exists(candidate)) return candidate;
                string candidateExe = Path.Combine(dir.Trim(), "flutter.exe");
                if (File.Exists(candidateExe)) return candidateExe;
            }

            return null;
        }

        static bool RunFlutterPubGet(string mobileDir, string flutterExe)
        {
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = flutterExe;
            psi.Arguments = "pub get";
            psi.WorkingDirectory = mobileDir;
            psi.UseShellExecute = false;

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
                PrintColor("[ERROR] Error running pub get: " + ex.Message, ConsoleColor.Red);
                return false;
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
