from flask import Flask, render_template_string, request, jsonify
from lxml import etree
from lxml.builder import E
import os

app = Flask(__name__, static_folder='static')

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
XML_PATH = os.path.join(BASE_DIR, "database.xml")
XSL_PATH = os.path.join(BASE_DIR, "weekly.xsl")


def load_xml():
    return etree.parse(XML_PATH)


def save_xml(tree):
    tree.write(XML_PATH, xml_declaration=True, encoding="UTF-8", pretty_print=True)


def get_transformed_html(view="all", filter_id=None):
    xml_doc = load_xml()
    xslt_doc = etree.parse(XSL_PATH)

    transform = etree.XSLT(xslt_doc)
    result = transform(xml_doc, view=etree.XSLT.strparam(view), filter_id=etree.XSLT.strparam(filter_id or ""))

    return str(result)


@app.route("/")
def index():
    view = request.args.get("view", "all")
    filter_id = request.args.get("filter_id", "")
    return render_template_string(get_transformed_html(view, filter_id))


@app.route("/api/classes")
def api_classes():
    tree = load_xml()
    classes = tree.xpath("//class")
    return jsonify([
        {"id": c.get("id"), "name": c.get("name"), "subjectRef": c.get("subjectRef"), "roomRefs": c.get("roomRefs").split()}
        for c in classes
    ])


@app.route("/api/teachers")
def api_teachers():
    tree = load_xml()
    professors = tree.xpath("//professor")
    return jsonify([
        {"id": p.get("id"), "name": p.get("name")}
        for p in professors
    ])


@app.route("/api/subjects")
def api_subjects():
    tree = load_xml()
    subjects = tree.xpath("//subject")
    return jsonify([
        {"id": s.get("id"), "name": s.get("name"), "color": s.get("color")}
        for s in subjects
    ])


@app.route("/api/rooms")
def api_rooms():
    tree = load_xml()
    rooms = tree.xpath("//room")
    return jsonify([
        {"id": r.get("id"), "name": r.get("name"), "capacity": r.get("capacity")}
        for r in rooms
    ])


def time_overlap(start1, end1, start2, end2):
    return start1 < end2 and start2 < end1


def check_conflicts(tree, day, start, end, class_ref, room_ref, professor_ref, exclude_session_id=None):
    sessions = tree.xpath(f'//session[day="{day}"]')
    conflicts = []

    for sess in sessions:
        if exclude_session_id and sess.xpath("id()") == exclude_session_id:
            continue

        sess_start = sess.find("start").text
        sess_end = sess.find("end").text

        if not time_overlap(start, end, sess_start, sess_end):
            continue

        if class_ref:
            sess_class = sess.find("classRef")
            if sess_class is not None and sess_class.text == class_ref:
                conflicts.append(f"Class already has a session at {sess_start}-{sess_end}")

        if room_ref:
            sess_room = sess.find("roomRef")
            if sess_room is not None and sess_room.text == room_ref:
                conflicts.append(f"Room already booked at {sess_start}-{sess_end}")

        if professor_ref:
            sess_prof = sess.find("professorRef")
            if sess_prof is not None and sess_prof.text == professor_ref:
                conflicts.append(f"Professor already teaching at {sess_start}-{sess_end}")

    return conflicts


@app.route("/api/sessions", methods=["POST"])
def add_session():
    data = request.json

    required = ["day", "start", "end", "subjectRef", "roomRef", "professorRef", "classRef"]
    for field in required:
        if field not in data:
            return jsonify({"status": "error", "message": f"Missing field: {field}"}), 400

    tree = load_xml()

    valid_classes = [c.get("id") for c in tree.xpath("//class")]
    if data["classRef"] not in valid_classes:
        return jsonify({"status": "error", "message": "Invalid class. Class is required."}), 400

    conflicts = check_conflicts(
        tree,
        data["day"],
        data["start"],
        data["end"],
        data["classRef"],
        data["roomRef"],
        data["professorRef"]
    )

    if conflicts:
        return jsonify({"status": "error", "message": "Conflicts: " + "; ".join(conflicts)}), 409

    sessions_elem = tree.xpath("//sessions")[0]

    new_session = E("session")
    new_session.append(E("day", data["day"]))
    new_session.append(E("start", data["start"]))
    new_session.append(E("end", data["end"]))
    new_session.append(E("subjectRef", data["subjectRef"]))
    new_session.append(E("roomRef", data["roomRef"]))
    new_session.append(E("professorRef", data["professorRef"]))
    new_session.append(E("classRef", data["classRef"]))

    sessions_elem.append(new_session)
    save_xml(tree)

    return jsonify({"status": "success"})


@app.route("/api/sessions/<session_id>", methods=["DELETE"])
def delete_session(session_id):
    tree = load_xml()
    session = tree.xpath(f'//session[contains(concat(" ", string(id()), " "), " {session_id} ")]')

    if not session:
        return jsonify({"status": "error", "message": "Session not found"}), 404

    session[0].getparent().remove(session[0])
    save_xml(tree)

    return jsonify({"status": "success"})


@app.route("/api/refresh")
def api_refresh():
    return jsonify({"status": "success", "html": get_transformed_html()})


if __name__ == "__main__":
    print("Scheduler Server Running at http://127.0.0.1:5000")
    app.run(debug=True)