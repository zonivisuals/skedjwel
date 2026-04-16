<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="html" indent="yes" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <xsl:param name="view">all</xsl:param>
  <xsl:param name="filter_id"></xsl:param>

  <xsl:key name="subject-by-id"   match="subject"   use="@id"/>
  <xsl:key name="room-by-id"      match="room"      use="@id"/>
  <xsl:key name="professor-by-id" match="professor"  use="@id"/>
  <xsl:key name="class-by-id"     match="class"     use="@id"/>
  <xsl:key name="sessions-by-day" match="session"    use="day"/>

  <xsl:template match="/timetable">
    <html>
      <head>
        <meta charset="UTF-8"/>
        <title>Weekly Timetable — <xsl:value-of select="@semester"/>&#160;<xsl:value-of select="@year"/></title>
        <style>
          *          { box-sizing: border-box; margin: 0; padding: 0; }
          body       { font-family: 'Segoe UI', Tahoma, Geneva, sans-serif;
                       background: #f4f5f9; padding: 28px; }
          h1         { color: #2c3e50; font-size: 1.5em; margin-bottom: 2px; }
          .subtitle  { color: #7f8c8d; font-size: 0.95em; margin-bottom: 22px; }
          #currentFilterLabel { color: #4A90D9; font-weight: 600; margin-left: 8px; }

          .view-nav   { margin-bottom: 16px; display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
          .view-nav   select { padding: 6px 10px; border: 1px solid #dde1e8; border-radius: 4px;
                              font-size: 0.9em; background: #fff; }
          .view-nav   label  { font-size: 0.9em; color: #555; }

          table      { border-collapse: collapse; width: 100%;
                       background: #fff; box-shadow: 0 2px 8px rgba(0,0,0,.07);
                       border-radius: 6px; overflow: hidden; }
          th         { background: #eef0f5; color: #2c3e50; font-weight: 600;
                       font-size: .82em; padding: 10px 6px; text-align: center;
                       border: 1px solid #dde1e8; }
          td         { border: 1px solid #dde1e8; vertical-align: top;
                       padding: 0; height: 58px; }

          .day-cell  { background: #eef0f5; font-weight: 600; text-align: center;
                       padding: 10px 8px; color: #2c3e50; width: 90px;
                       vertical-align: middle; font-size: .88em; }
          .empty-cell{ background: #fafbfd; position: relative; }
          .empty-cell:hover { background: #e8f4fc; }

          .add-btn   { display: none; position: absolute; top: 50%; left: 50%;
                      transform: translate(-50%, -50%); width: 28px; height: 28px;
                      border-radius: 50%; border: 2px solid #4A90D9; background: #fff;
                      color: #4A90D9; font-size: 18px; cursor: pointer;
                      line-height: 1; font-weight: bold; }
          .empty-cell:hover .add-btn { display: block; }
          .add-btn:hover { background: #4A90D9; color: #fff; }

          .sess      { padding: 7px 9px; margin: 2px; border-radius: 4px;
                       font-size: .8em; line-height: 1.45; position: relative; }
          .sess .sn  { font-weight: 700; display: block; margin-bottom: 1px; }
          .sess .sr  { color: #555; }
          .sess .sp  { color: #888; font-style: italic; margin-left: 6px; }
          .sess .sc  { color: #aaa; font-size: 0.9em; margin-left: 6px; }

          .toast     { position: fixed; bottom: 20px; right: 20px; padding: 12px 20px;
                       border-radius: 6px; color: #fff; font-size: 0.9em;
                       display: none; z-index: 1000; }
          .toast.error { background: #e74c3c; }
          .toast.success { background: #27ae60; }

          .modal { display: none; position: fixed; z-index: 2000; left: 0; top: 0; width: 100%; height: 100%;
                   background: rgba(0,0,0,0.5); }
          .modal.active { display: block; }
          .modal-content { background: #fff; margin: 10% auto; padding: 24px; border-radius: 8px;
                           width: 420px; box-shadow: 0 4px 20px rgba(0,0,0,0.2); }
          .modal-content h2 { margin-bottom: 4px; color: #2c3e50; }
          .modal-content .modal-info { color: #7f8c8d; margin-bottom: 16px; font-size: 0.9em; }
          .modal-content .form-group { margin-bottom: 12px; }
          .modal-content .form-group label { display: block; margin-bottom: 4px; font-size: 0.85em; color: #555; }
          .modal-content .form-group select { width: 100%; padding: 8px; border: 1px solid #dde1e8;
                                           border-radius: 4px; font-size: 0.9em; background: #fff; }
          .modal-content .form-group select:disabled { background: #eef0f5; color: #888; }
          .modal-content .form-group.hidden { display: none; }
          .modal-content .btn-row { display: flex; gap: 8px; margin-top: 16px; }
          .modal-content .btn-row button { flex: 1; padding: 10px; border: none; border-radius: 4px;
                                          font-size: 0.9em; cursor: pointer; }
          .modal-content .btn-row .submit-btn { background: #4A90D9; color: #fff; }
          .modal-content .btn-row .cancel-btn { background: #e0e0e0; color: #333; }
          .modal-close { position: absolute; right: 16px; top: 12px; font-size: 24px; cursor: pointer;
                        color: #999; }
          .modal-close:hover { color: #333; }
        </style>
        <script src="/static/timetable.js"></script>
      </head>
      <body>
        <h1>Weekly Timetable <span id="currentFilterLabel" class="filter-tag"></span></h1>
        <p class="subtitle">
          <xsl:value-of select="@semester"/>&#160;<xsl:value-of select="@year"/>
        </p>

        <div class="view-nav">
          <label>View:</label>
          <select id="viewSelect">
            <option value="all">All Sessions</option>
            <option value="class">By Class</option>
            <option value="teacher">By Teacher</option>
          </select>
          <select id="filterSelect" style="display:none">
            <option value="">Select...</option>
          </select>
        </div>

        <table data-view="{$view}" data-filter-id="{$filter_id}">
          <thead>
            <tr>
              <th>&#160;</th>
              <xsl:for-each select="config/slots/slot">
                <th><xsl:value-of select="@time"/></th>
              </xsl:for-each>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="config/days/day">
              <xsl:variable name="day" select="."/>
              <xsl:variable name="all-sessions" select="key('sessions-by-day', $day)"/>
              <xsl:variable name="filter-class" select="$filter_id"/>
              <xsl:variable name="filter-teacher" select="$filter_id"/>
              <xsl:variable name="filtered-sessions" select="$all-sessions[($view = 'all' or $view = '') or ($view = 'class' and classRef = $filter-class) or ($view = 'teacher' and professorRef = $filter-teacher)]"/>

              <tr>
                <td class="day-cell"><xsl:value-of select="$day"/></td>

                <xsl:for-each select="/timetable/config/slots/slot">
                  <xsl:variable name="t" select="@time"/>
                  <xsl:variable name="tn" select="number(translate($t, ':', ''))"/>

                  <xsl:variable name="all-sess" select="$filtered-sessions"/>
                  <xsl:variable name="starts" select="$all-sess[number(translate(start,':','')) = $tn]"/>
                  <xsl:variable name="covered" select="$all-sess[number(translate(start,':','')) &lt; $tn and number(translate(end,':','')) &gt; $tn]"/>

                  <xsl:choose>
                    <xsl:when test="$starts">
                      <xsl:variable name="endN" select="number(translate($starts/end, ':', ''))"/>
                      <xsl:variable name="span" select="count(/timetable/config/slots/slot [number(translate(@time,':','')) &gt;= $tn and number(translate(@time,':','')) &lt; $endN])"/>
                      <td colspan="{$span}">
                        <xsl:apply-templates select="$starts" mode="cell"/>
                      </td>
                    </xsl:when>
                    <xsl:when test="$covered"/>
                    <xsl:otherwise>
                      <td class="empty-cell">
                        <button class="add-btn" onclick="openModal('{$day}', '{$t}')">+</button>
                      </td>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </tr>
            </xsl:for-each>
          </tbody>
        </table>

        <div id="sessionModal" class="modal">
          <div class="modal-content">
            <span class="modal-close" onclick="closeModal()">×</span>
            <h2>Add Session</h2>
            <p class="modal-info" id="modalInfo"></p>
            <form id="sessionForm">
              <div class="form-group" id="classGroup">
                <label>Class</label>
                <select id="classSelect"><option value="">Select class...</option></select>
              </div>
              <div class="form-group hidden" id="subjectGroup">
                <label>Subject</label>
                <select id="subjectSelect"><option value="">Select subject...</option></select>
              </div>
              <div class="form-group hidden" id="roomGroup">
                <label>Room</label>
                <select id="roomSelect"><option value="">Select room...</option></select>
              </div>
              <div class="form-group hidden" id="professorGroup">
                <label>Professor</label>
                <select id="professorSelect"><option value="">Select professor...</option></select>
              </div>
              <div class="btn-row">
                <button type="button" class="submit-btn" onclick="submitSession()">Add Session</button>
                <button type="button" class="cancel-btn" onclick="closeModal()">Cancel</button>
              </div>
            </form>
          </div>
        </div>

        <div id="toast" class="toast"></div>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="session" mode="cell">
    <xsl:variable name="subj" select="key('subject-by-id', subjectRef)"/>
    <xsl:variable name="room" select="key('room-by-id', roomRef)"/>
    <xsl:variable name="prof" select="key('professor-by-id', professorRef)"/>
    <xsl:variable name="class" select="key('class-by-id', classRef)"/>

    <xsl:choose>
      <xsl:when test="$class">
        <div class="sess" style="border-left:4px solid {$subj/@color}; background:{$subj/@color}18;">
          <span class="sn"><xsl:value-of select="$subj/@name"/></span>
          <span class="sr"><xsl:value-of select="$room/@name"/></span>
          <span class="sp"><xsl:value-of select="$prof/@name"/></span>
          <span class="sc"><xsl:value-of select="$class/@name"/></span>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <div class="sess sess-warning" style="border-left:4px solid #e74c3c; background:#e74c3c18;">
          <span class="sn"><xsl:value-of select="$subj/@name"/></span>
          <span class="sr"><xsl:value-of select="$room/@name"/></span>
          <span class="sp"><xsl:value-of select="$prof/@name"/></span>
          <span class="sc" style="color:#e74c3c;font-weight:bold;">Missing Class</span>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>