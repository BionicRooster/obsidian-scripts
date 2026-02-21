/*
 * Connect.cs
 *
 * The main COM add-in class for the OneNote → Obsidian exporter.
 *
 * Implements:
 *   IDTExtensibility2         — the standard Office add-in lifecycle interface
 *   IRibbonExtensibility      — provides the custom ribbon XML to OneNote
 *
 * When OneNote loads this add-in it calls:
 *   1. GetCustomUI()          — to read the ribbon XML and build the button
 *   2. OnStartupComplete()    — after the UI is fully initialised
 *   3. ExportToObsidian()     — each time the user clicks the ribbon button
 *
 * Registration (done by Install.ps1):
 *   RegAsm registers the class as a COM server, then the registry key
 *   HKCU\Software\Microsoft\Office\OneNote\Addins\OneNoteExportAddin.Connect
 *   tells OneNote to load it at startup.
 */

using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using Extensibility;
using Microsoft.Office.Core; // defined in ComInterfaces.cs — no office.dll needed

namespace OneNoteExportAddin
{
    // -----------------------------------------------------------------------
    // COM registration attributes
    //   ComVisible(true)              — exposes this class to COM callers
    //   Guid(...)                     — stable CLSID; must never change after
    //                                   first registration or existing registry
    //                                   entries will become stale
    //   ProgId(...)                   — human-readable COM identifier used in
    //                                   the OneNote add-ins registry key
    //   ClassInterface(AutoDual)      — CLR auto-generates a dual (IDispatch +
    //                                   vtable) class interface that exposes all
    //                                   public methods by name.  Office finds
    //                                   OnConnection, GetCustomUI, etc. via
    //                                   IDispatch without needing an exact IID.
    // -----------------------------------------------------------------------

    [ComVisible(true)]
    [Guid("C1E7A840-D4B5-4E8B-B63F-0A4E7C3A9E1F")]
    [ProgId("OneNoteExportAddin.Connect")]
    [ClassInterface(ClassInterfaceType.AutoDual)]
    public class Connect : IDTExtensibility2, IRibbonExtensibility
    {
        // -------------------------------------------------------------------
        // Constants
        // -------------------------------------------------------------------

        /// <summary>
        /// Absolute path to the batch file that launches the Python exporter.
        /// This is what actually runs when the user clicks the ribbon button.
        /// </summary>
        private const string BatchFile = @"C:\Users\awt\run_onenote_export.bat";

        /// <summary>Log file written on every lifecycle event for diagnostics.</summary>
        private const string LogFile = @"C:\Users\awt\onenote_addin_log.txt";

        // -------------------------------------------------------------------
        // Logging helper
        // -------------------------------------------------------------------

        /// <summary>Append a timestamped line to the diagnostic log file.</summary>
        private static void Log(string message)
        {
            try
            {
                File.AppendAllText(LogFile,
                    $"{DateTime.Now:yyyy-MM-dd HH:mm:ss}  {message}\r\n");
            }
            catch { /* never let logging crash the add-in */ }
        }

        // -------------------------------------------------------------------
        // IDTExtensibility2  —  Office add-in lifecycle
        //
        // Most methods are intentionally empty: we have no startup/shutdown
        // work to do.  The methods must exist because IDTExtensibility2
        // requires them.
        // -------------------------------------------------------------------

        /// <summary>
        /// Called when OneNote connects (loads) this add-in.
        /// Application  : the OneNote.Application COM object.
        /// ConnectMode  : indicates whether this is a startup load, post-startup
        ///                load, or triggered externally.
        /// AddInInst    : the COMAddIn entry for this add-in in OneNote's collection.
        /// custom       : reserved; not used.
        /// </summary>
        public void OnConnection(
            object Application,
            ext_ConnectMode ConnectMode,
            object AddInInst,
            ref Array custom)
        {
            try { Log($"OnConnection called. ConnectMode={ConnectMode}"); }
            catch (Exception ex) { Log("OnConnection exception: " + ex); }
        }

        /// <summary>Called when OneNote disconnects (unloads) this add-in.</summary>
        public void OnDisconnection(ext_DisconnectMode RemoveMode, ref Array custom)
        {
            Log($"OnDisconnection called. RemoveMode={RemoveMode}");
        }

        /// <summary>Called when any installed add-in is added or removed.</summary>
        public void OnAddInsUpdate(ref Array custom) { Log("OnAddInsUpdate called."); }

        /// <summary>Called after OneNote has finished its startup sequence.</summary>
        public void OnStartupComplete(ref Array custom) { Log("OnStartupComplete called."); }

        /// <summary>Called just before OneNote begins shutting down.</summary>
        public void OnBeginShutdown(ref Array custom) { Log("OnBeginShutdown called."); }

        // -------------------------------------------------------------------
        // IRibbonExtensibility  —  ribbon UI definition
        // -------------------------------------------------------------------

        /// <summary>
        /// Returns the Ribbon XML that OneNote uses to build our custom tab
        /// and button.  Called once when the ribbon is initialised.
        ///
        /// RibbonID : identifies which application ribbon is being built
        ///            (always "Microsoft.OneNote.NoteBook" for OneNote).
        /// </summary>
        public string GetCustomUI(string RibbonID)
        {
            Log($"GetCustomUI called. RibbonID={RibbonID}");
            // customUI namespace: 2009/07 version supports size="large" buttons.
            // The onAction callback name must exactly match a public method on
            // this class that accepts an IRibbonControl parameter.
            return
                "<customUI xmlns='http://schemas.microsoft.com/office/2009/07/customui'>" +
                "  <ribbon>" +
                "    <tabs>" +
                "      <tab id='tabExport' label='Export'>" +
                "        <group id='grpObsidian' label='Obsidian'>" +
                "          <button id='btnExportToObsidian'" +
                "                  label='Export to Obsidian'" +
                "                  screentip='Export current page to Obsidian'" +
                "                  supertip='Converts the currently focused OneNote page to a Markdown note and saves it to your Obsidian vault.'" +
                "                  size='large'" +
                "                  onAction='ExportToObsidian'/>" +
                "        </group>" +
                "      </tab>" +
                "    </tabs>" +
                "  </ribbon>" +
                "</customUI>";
        }

        // -------------------------------------------------------------------
        // Button callback
        // -------------------------------------------------------------------

        /// <summary>
        /// Invoked by OneNote when the user clicks the "Export to Obsidian"
        /// ribbon button.  Launches run_onenote_export.bat in its own window
        /// so the Python script can connect to OneNote's COM server.
        ///
        /// control : the IRibbonControl object representing the clicked button
        ///           (not used here, but required by the ribbon callback signature).
        /// </summary>
        public void ExportToObsidian(IRibbonControl control)
        {
            try
            {
                // ProcessStartInfo: UseShellExecute=true so Windows associates
                // the .bat extension with cmd.exe correctly, and the process
                // runs in a proper interactive desktop session — the same session
                // OneNote is in — which allows the Python script's win32com
                // GetActiveObject call to find the OneNote COM server.
                var psi = new ProcessStartInfo
                {
                    FileName        = BatchFile,
                    UseShellExecute = true,
                    WindowStyle     = ProcessWindowStyle.Normal
                };
                Process.Start(psi);
            }
            catch (Exception ex)
            {
                // Show a dialog so the user knows something went wrong.
                MessageBox.Show(
                    "Failed to launch the Obsidian exporter:\n\n" + ex.Message,
                    "OneNote Obsidian Export",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }
    }
}
