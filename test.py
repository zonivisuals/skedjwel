from app import get_transformed_html

h = get_transformed_html()
print('viewSelect in HTML:', 'viewSelect' in h)
print('viewSelect id:', 'id="viewSelect"' in h)
print('static/timetable.js:', '/static/timetable.js' in h)