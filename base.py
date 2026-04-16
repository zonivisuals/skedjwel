from lxml import etree

# 1. Load XML Data and XSLT Stylesheet
xml_db = etree.parse("timetable.xml")
xslt_style = etree.parse("weekly.xsl")

# 2. Transform
transform = etree.XSLT(xslt_style)
result_html = transform(xml_db)

# 3. Output to Browser/File
with open("index.html", "wb") as f:
    f.write(result_html)