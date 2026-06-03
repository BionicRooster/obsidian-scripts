"""Fetch the raw XML of the current OneNote page to inspect the format."""
import pythoncom, comtypes.client

pythoncom.CoInitialize()
lib = comtypes.client.GetModule(("{0EA692EE-BB50-4E3C-AEF0-356D91732725}", 1, 1, 0))
app = comtypes.client.CreateObject("OneNote.Application", interface=lib.IApplication)

windows    = app.Windows
window     = windows[0]
section_id = window.CurrentSectionId
print("Section ID:", section_id)

# Get page XML for the current page
import xml.etree.ElementTree as ET
hierarchy_xml = app.GetHierarchy("", 4)   # HS_PAGES = 4
root = ET.fromstring(hierarchy_xml)
NS = "http://schemas.microsoft.com/office/onenote/2013/onenote"

# Find a page in the current section
pages = root.findall(f".//{{{NS}}}Page")
print(f"Found {len(pages)} pages in hierarchy")
if pages:
    page = pages[0]
    pid  = page.get("ID")
    print("Using page:", page.get("name"), "ID:", pid)
    content = app.GetPageContent(pid, 7)   # PI_ALL=7
    # Save the raw XML so we can inspect it
    with open(r"C:\Users\awt\page_sample.xml", "w", encoding="utf-8") as f:
        f.write(content)
    print("Saved to C:\\Users\\awt\\page_sample.xml")
    # Also show the first 2000 chars
    print(content[:2000])

pythoncom.CoUninitialize()
