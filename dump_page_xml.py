"""Dump raw XML of the current OneNote page to a file for inspection."""
import pythoncom, comtypes.client

pythoncom.CoInitialize()
lib = comtypes.client.GetModule(("{0EA692EE-BB50-4E3C-AEF0-356D91732725}", 1, 1, 0))
app = comtypes.client.CreateObject("OneNote.Application", interface=lib.IApplication)
windows = app.Windows
window  = windows[0]
page_id = window.CurrentPageId
content = app.GetPageContent(page_id, 7)  # PI_ALL=7
with open(r"C:\Users\awt\current_page.xml", "w", encoding="utf-8") as f:
    f.write(content)
print(f"Saved {len(content)} chars to current_page.xml")
pythoncom.CoUninitialize()
