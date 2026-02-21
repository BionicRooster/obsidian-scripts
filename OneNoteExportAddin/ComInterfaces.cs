/*
 * ComInterfaces.cs
 *
 * Definitions of enums needed by the IDTExtensibility2 lifecycle methods.
 *
 * Why no [ComImport] on IDTExtensibility2?
 *   Office calls add-in lifecycle methods via IDispatch (late binding) using
 *   the method names, not by vtable offset.  Defining IDTExtensibility2 as a
 *   plain .NET interface (no [ComImport] / no GUID) is therefore sufficient
 *   and avoids interface-identity mismatches that occur when the CLR's idea of
 *   the IID doesn't agree with the one Office has baked into its caller code.
 *
 *   The Connect class uses [ClassInterface(AutoDual)] so the CLR generates a
 *   dual (IDispatch + vtable) class interface that exposes all public methods —
 *   including the IDTExtensibility2 methods — to COM callers by name.
 */

using System;
using System.Runtime.InteropServices;

// ---------------------------------------------------------------------------
// Microsoft.Office.Core  —  ribbon extensibility interfaces
//
// Defined here as plain .NET interfaces (no [ComImport]) to avoid a runtime
// dependency on office.dll, which can fail to resolve in OneNote's process.
// The AutoDual class interface on Connect exposes these methods via IDispatch,
// which is how Office discovers and calls ribbon callbacks.
// ---------------------------------------------------------------------------
namespace Microsoft.Office.Core
{
    /// <summary>
    /// Implemented by a COM add-in to supply custom ribbon XML.
    /// OneNote calls GetCustomUI() once during startup to build the ribbon.
    /// </summary>
    public interface IRibbonExtensibility
    {
        /// <summary>
        /// Return the ribbon XML string that defines the add-in's UI.
        /// RibbonID identifies which application ribbon is being constructed.
        /// </summary>
        string GetCustomUI(string RibbonID);
    }

    /// <summary>
    /// Passed to ribbon callback methods (e.g. onAction handlers).
    /// Provides context about which control was activated.
    /// </summary>
    public interface IRibbonControl
    {
        /// <summary>The id attribute of the activated ribbon control.</summary>
        string Id  { get; }

        /// <summary>The tag attribute of the activated ribbon control.</summary>
        string Tag { get; }

        /// <summary>The document context in which the control was activated.</summary>
        object Context { get; }
    }
}

namespace Extensibility
{
    // -----------------------------------------------------------------------
    // IDTExtensibility2  —  standard Office COM add-in lifecycle interface
    //
    // Defined here as a plain .NET interface.  The Connect class implements
    // it and exposes the methods through its AutoDual class interface, which
    // Office discovers via IDispatch.GetIDsOfNames / Invoke.
    // -----------------------------------------------------------------------

    /// <summary>
    /// Office COM add-in lifecycle interface.  Every Office application
    /// (Word, Excel, OneNote, …) calls these methods as it loads, connects,
    /// and unloads the add-in.
    /// </summary>
    public interface IDTExtensibility2
    {
        /// <summary>Called when the add-in is connected (loaded by the host).</summary>
        /// <param name="Application">The host COM application object.</param>
        /// <param name="ConnectMode">Reason for connection (startup, external, …).</param>
        /// <param name="AddInInst">The COMAddIn entry for this add-in.</param>
        /// <param name="custom">Reserved; not used.</param>
        void OnConnection(
            object Application,
            ext_ConnectMode ConnectMode,
            object AddInInst,
            ref Array custom);

        /// <summary>Called when the add-in is disconnected.</summary>
        void OnDisconnection(ext_DisconnectMode RemoveMode, ref Array custom);

        /// <summary>Called when the installed add-in list changes.</summary>
        void OnAddInsUpdate(ref Array custom);

        /// <summary>Called after the host has finished starting up.</summary>
        void OnStartupComplete(ref Array custom);

        /// <summary>Called just before the host begins shutting down.</summary>
        void OnBeginShutdown(ref Array custom);
    }

    // -----------------------------------------------------------------------
    // ext_ConnectMode  —  why the add-in was connected
    // -----------------------------------------------------------------------

    /// <summary>Describes the circumstances under which an add-in was connected.</summary>
    public enum ext_ConnectMode
    {
        /// <summary>Connected after the host application finished starting.</summary>
        ext_cm_AfterStartup = 0,

        /// <summary>Connected during host application startup.</summary>
        ext_cm_Startup = 1,

        /// <summary>Connected by an external caller (e.g. another add-in).</summary>
        ext_cm_External = 2,

        /// <summary>Connected from the command line.</summary>
        ext_cm_CommandLine = 3
    }

    // -----------------------------------------------------------------------
    // ext_DisconnectMode  —  why the add-in was disconnected
    // -----------------------------------------------------------------------

    /// <summary>Describes the circumstances under which an add-in was disconnected.</summary>
    public enum ext_DisconnectMode
    {
        /// <summary>Disconnected because the host application is shutting down.</summary>
        ext_dm_HostShutdown = 0,

        /// <summary>Disconnected because the user disabled or removed the add-in.</summary>
        ext_dm_UserClosed = 1
    }
}
