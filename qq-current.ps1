param([ValidateSet('capture','type','sendDraft','send')][string]$Action='capture',[string]$Message='',[Parameter(Mandatory=$true)][long]$WindowHandle)
$ErrorActionPreference='Stop'
if ($Action -ne 'capture') {
 $qqTokenGroups = whoami /groups /fo csv
 if (($qqTokenGroups -join "`n") -match 'S-1-16-(0|4096)(?:[^0-9]|$)') {
  throw 'Desktop input is unavailable from this low-integrity execution environment. No message was typed or sent. Use an approved desktop-input environment.'
 }
}
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class QQCurrentInput {
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern uint SendInput(uint n, INPUT[] inputs, int size);
 [StructLayout(LayoutKind.Sequential)] public struct INPUT { public uint type; public UNION u; }
 [StructLayout(LayoutKind.Explicit)] public struct UNION { [FieldOffset(0)] public MOUSE mi; [FieldOffset(0)] public KEY ki; }
 [StructLayout(LayoutKind.Sequential)] public struct MOUSE { public int dx,dy; public uint data,flags,time; public UIntPtr extra; }
 [StructLayout(LayoutKind.Sequential)] public struct KEY { public ushort vk,scan; public uint flags,time; public UIntPtr extra; }
 public static void Click() { INPUT a=new INPUT(); a.type=0; a.u.mi.flags=2; INPUT b=a; b.u.mi.flags=4; if(SendInput(2,new INPUT[]{a,b},Marshal.SizeOf(typeof(INPUT)))!=2) throw new Exception("Mouse input denied."); }
 public static void Text(string s) { foreach(char c in s) { INPUT a=new INPUT(); a.type=1; a.u.ki.scan=c; a.u.ki.flags=4; INPUT b=a; b.u.ki.flags=6; uint n=SendInput(2,new INPUT[]{a,b},Marshal.SizeOf(typeof(INPUT))); if(n!=2) throw new Exception("SendInput returned "+n+", structure size "+Marshal.SizeOf(typeof(INPUT))); } }
 public static void Enter() { INPUT a=new INPUT(); a.type=1; a.u.ki.vk=13; INPUT b=a; b.u.ki.flags=2; SendInput(2,new INPUT[]{a,b},Marshal.SizeOf(typeof(INPUT))); }
}
'@
if ([QQCurrentInput]::GetForegroundWindow().ToInt64() -ne $WindowHandle) { throw 'The authorized QQ window is no longer foreground.' }
$qqWindow=[System.Windows.Automation.AutomationElement]::FromHandle([intptr]$WindowHandle)
if ($qqWindow.Current.Name -ne 'QQ') { throw 'QQ window identity changed.' }
$qqBounds=$qqWindow.Current.BoundingRectangle
if ($Action -ne 'capture' -and ($qqBounds.Width -notin @(1611,1613) -or $qqBounds.Height -notin @(1278,1368))) { throw 'Window layout changed. Recheck input and send coordinates before continuing.' }
if ($Action -eq 'type' -or $Action -eq 'send') {
 if (-not $Message) { throw 'Empty message.' }
 [void][QQCurrentInput]::SetCursorPos([int]($qqBounds.X+700),[int]($qqBounds.Y+$qqBounds.Height-160))
 [QQCurrentInput]::Click()
 [QQCurrentInput]::Text($Message)
 Start-Sleep -Milliseconds 250
 Start-Sleep -Milliseconds 700
}
if ($Action -eq 'sendDraft' -or $Action -eq 'send') {
 [void][QQCurrentInput]::SetCursorPos([int]($qqBounds.X+1230),[int]($qqBounds.Bottom-48))
 if ([QQCurrentInput]::GetForegroundWindow().ToInt64() -ne $WindowHandle) { throw 'Foreground changed before sending.' }
 [QQCurrentInput]::Click()
 Start-Sleep -Milliseconds 900
}
$qqBitmap=New-Object System.Drawing.Bitmap ([int]$qqBounds.Width),([int]$qqBounds.Height)
$qqGraphics=[System.Drawing.Graphics]::FromImage($qqBitmap)
$qqGraphics.CopyFromScreen([int]$qqBounds.X,[int]$qqBounds.Y,0,0,$qqBitmap.Size)
$qqBitmap.Save((Join-Path $PSScriptRoot 'qq-current.png'))
$qqGraphics.Dispose()
$qqBitmap.Dispose()
