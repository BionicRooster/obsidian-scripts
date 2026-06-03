"""
create_test_page.py

Creates a OneNote test page with a table via COM, then navigates to it.
Run this, then click the tray icon to export it.
"""

import pythoncom
import comtypes.client

# OneNote XML namespace
NS = "http://schemas.microsoft.com/office/onenote/2013/onenote"

# Page XML with a header row + 3 data rows
PAGE_XML = """\
<?xml version="1.0"?>
<one:Page xmlns:one="http://schemas.microsoft.com/office/onenote/2013/onenote">
  <one:Title><one:OE><one:T><![CDATA[Table Test Page]]></one:T></one:OE></one:Title>
  <one:Outline>
    <one:OEChildren>
      <one:OE><one:T><![CDATA[Here is a test table:]]></one:T></one:OE>
      <one:Table hasHeaderRow="true" bordersVisible="true">
        <one:Row>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[Name]]></one:T></one:OE></one:OEChildren></one:Cell>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[Role]]></one:T></one:OE></one:OEChildren></one:Cell>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[Location]]></one:T></one:OE></one:OEChildren></one:Cell>
        </one:Row>
        <one:Row>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[Alice]]></one:T></one:OE></one:OEChildren></one:Cell>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[Engineer]]></one:T></one:OE></one:OEChildren></one:Cell>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[New York]]></one:T></one:OE></one:OEChildren></one:Cell>
        </one:Row>
        <one:Row>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[Bob]]></one:T></one:OE></one:OEChildren></one:Cell>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[Designer]]></one:T></one:OE></one:OEChildren></one:Cell>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[Chicago]]></one:T></one:OE></one:OEChildren></one:Cell>
        </one:Row>
        <one:Row>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[Carol]]></one:T></one:OE></one:OEChildren></one:Cell>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[Manager]]></one:T></one:OE></one:OEChildren></one:Cell>
          <one:Cell><one:OEChildren><one:OE><one:T><![CDATA[Austin]]></one:T></one:OE></one:OEChildren></one:Cell>
        </one:Row>
      </one:Table>
      <one:OE><one:T><![CDATA[End of table.]]></one:T></one:OE>
    </one:OEChildren>
  </one:Outline>
</one:Page>
"""

def main():
    # Initialize COM for this thread
    pythoncom.CoInitialize()

    try:
        # Connect to OneNote via comtypes (same approach as the tray)
        onenote_lib = comtypes.client.GetModule(
            ("{0EA692EE-BB50-4E3C-AEF0-356D91732725}", 1, 1, 0)
        )
        app = comtypes.client.CreateObject(
            "OneNote.Application",
            interface=onenote_lib.IApplication,
        )
        print("Connected to OneNote.")

        # Get the current section ID from the active window
        windows = app.Windows
        window  = windows[0]
        section_id = window.CurrentSectionId
        print(f"Current section ID: {section_id}")

        # Create a new blank page at the end of the section
        # CreateNewPage returns the new page ID via [out] parameter
        page_id = app.CreateNewPage(section_id)
        print(f"Created page ID: {page_id}")

        # Inject our page XML — we must include the pageID so OneNote
        # knows which page to update
        xml_with_id = PAGE_XML.replace(
            "<one:Page ",
            f'<one:Page ID="{page_id}" ',
        )
        # dateExpectedLastModified=0.0 means "don't check last-modified date"
        app.UpdatePageContent(xml_with_id, 0.0)
        print("Page content updated with table.")

        # Navigate to the new page so it's focused in OneNote
        app.NavigateTo(page_id)
        print("Navigated to page. Now click the tray icon to export it.")

    finally:
        pythoncom.CoUninitialize()

if __name__ == "__main__":
    main()
