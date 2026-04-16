<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="html" indent="yes" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <!--
    Lookup keys — the backbone of the DRY pattern.
    Each key lets us jump from a reference (e.g. "CS101")
    straight to the master entity in O(1).
  -->
  <xsl:key name="subject-by-id"   match="subject"   use="@id"/>
  <xsl:key name="room-by-id"      match="room"      use="@id"/>
  <xsl:key name="professor-by-id" match="professor"  use="@id"/>
  <xsl:key name="sessions-by-day" match="session"    use="day"/>


  <!-- ═══════════════════════════════════════════
       MAIN TEMPLATE — builds the entire page
       ═══════════════════════════════════════════ -->
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
          .empty-cell{ background: #fafbfd; }

          .sess      { padding: 7px 9px; margin: 2px; border-radius: 4px;
                       font-size: .8em; line-height: 1.45; }
          .sess .sn  { font-weight: 700; display: block; margin-bottom: 1px; }
          .sess .sr  { color: #555; }
          .sess .sp  { color: #888; font-style: italic; margin-left: 6px; }
        </style>
      </head>
      <body>
        <h1>Weekly Timetable</h1>
        <p class="subtitle">
          <xsl:value-of select="@semester"/>&#160;<xsl:value-of select="@year"/>
        </p>

        <table>
          <!-- ── Column headers: one per time slot ── -->
          <thead>
            <tr>
              <th>&#160;</th>
              <xsl:for-each select="config/slots/slot">
                <th><xsl:value-of select="@time"/></th>
              </xsl:for-each>
            </tr>
          </thead>

          <!-- ── One row per day ── -->
          <tbody>
            <xsl:for-each select="config/days/day">
              <!--
                Grab every session on this day via the key.
                $day is a string like "Monday".
              -->
              <xsl:variable name="day"     select="."/>
              <xsl:variable name="sessions" select="key('sessions-by-day', $day)"/>

              <tr>
                <td class="day-cell"><xsl:value-of select="$day"/></td>

                <!-- Walk every time-slot column -->
                <xsl:for-each select="/timetable/config/slots/slot">
                  <xsl:variable name="t"  select="@time"/>
                  <!-- Convert "HH:MM" → numeric HHMM for reliable comparison -->
                  <xsl:variable name="tn" select="number(translate($t, ':', ''))"/>

                  <!-- Does a session START exactly at this slot? -->
                  <xsl:variable name="starts"
                    select="$sessions[number(translate(start,':','')) = $tn]"/>

                  <!-- Is this slot COVERED by a session that began earlier? -->
                  <xsl:variable name="covered"
                    select="$sessions[number(translate(start,':','')) &lt; $tn
                            and number(translate(end,':','')) &gt; $tn]"/>

                  <xsl:choose>

                    <!-- ── Case 1: a session starts here → render with colspan ── -->
                    <xsl:when test="$starts">
                      <xsl:variable name="endN"
                        select="number(translate($starts/end, ':', ''))"/>
                      <!-- Count how many slot-columns this session spans -->
                      <xsl:variable name="span"
                        select="count(/timetable/config/slots/slot
                                [number(translate(@time,':','')) &gt;= $tn
                                 and number(translate(@time,':','')) &lt; $endN])"/>
                      <td colspan="{$span}">
                        <xsl:apply-templates select="$starts" mode="cell"/>
                      </td>
                    </xsl:when>

                    <!-- ── Case 2: covered by a prior colspan → emit no <td> ── -->
                    <xsl:when test="$covered"/>

                    <!-- ── Case 3: empty slot ── -->
                    <xsl:otherwise>
                      <td class="empty-cell">&#160;</td>
                    </xsl:otherwise>

                  </xsl:choose>
                </xsl:for-each>
              </tr>
            </xsl:for-each>
          </tbody>
        </table>
      </body>
    </html>
  </xsl:template>


  <!-- ═══════════════════════════════════════════
       SESSION CELL — resolves subject/room/prof
       ═══════════════════════════════════════════ -->
  <xsl:template match="session" mode="cell">
    <xsl:variable name="subj" select="key('subject-by-id',   subjectRef)"/>
    <xsl:variable name="room" select="key('room-by-id',      roomRef)"/>
    <xsl:variable name="prof" select="key('professor-by-id', professorRef)"/>

    <div class="sess"
         style="border-left:4px solid {$subj/@color};
                background:{$subj/@color}18;">
      <span class="sn"><xsl:value-of select="$subj/@name"/></span>
      <span class="sr"><xsl:value-of select="$room/@name"/></span>
      <span class="sp"><xsl:value-of select="$prof/@name"/></span>
    </div>
  </xsl:template>

</xsl:stylesheet>
