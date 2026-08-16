import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! Watch face with concentric partial rings between two sparse number dials: a
//! 60-scale near the rim and a 12-scale near the center. Each ring is a thin arc
//! from 12 o'clock; a radial tick links its end to its value, printed on the
//! outer or inner dial (per `Ring.tickOutward`). Only the values currently in
//! use are drawn - there is no full printed dial.
//!
//! Add or reorder rings in `collectRings()` (outermost first).
class BoussoleView extends WatchUi.WatchFace {

    private const RING_PEN = 3.0;                  // arc + tick thickness, px
    private const FONT_FACE = "RobotoCondensedBold";
    private const SUNRISE_COLOR = Graphics.COLOR_ORANGE;
    private const SUNSET_COLOR = Graphics.COLOR_BLUE;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2.0;
        var centerY = height / 2.0;
        var screenRadius = (width < height ? width : height) / 2.0;

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var font = resolveFont((screenRadius * 0.10).toNumber());
        var fontHeight = dc.getFontHeight(font);

        // Visible connector length between an arc's end and its number.
        var tickLen = 12.0;
        var labelPad = fontHeight / 2.0 + 2.0;  // clearance from number centre to tick

        // Number dials: outer a little in from the rim, inner near the centre.
        var outerLabelR = screenRadius - fontHeight / 2.0 - 10.0;
        var innerLabelR = screenRadius * 0.28;

        // Arc band sits one tick length inside each number dial, so every tick
        // spans arc -> number cleanly without crowding or overshooting.
        var arcOuter = outerLabelR - labelPad - tickLen;
        var arcInner = innerLabelR + labelPad + tickLen;

        var rings = collectRings();
        var n = rings.size();
        for (var i = 0; i < n; i++) {
            var t = (n <= 1) ? 0.5 : i.toFloat() / (n - 1);
            var arcRadius = arcOuter - t * (arcOuter - arcInner);
            var labelRadius = rings[i].tickOutward ? outerLabelR : innerLabelR;
            drawRing(
                dc, centerX, centerY, arcRadius, labelRadius, font, fontHeight,
                rings[i].fraction(), rings[i].label
            );
        }

        // Next sun event marked on the minutes ring (outer) and hours ring (inner).
        drawNextSunEvent(dc, centerX, centerY, arcOuter, arcInner);
    }

    //! Prefer a small scalable vector font; fall back to the smallest system font.
    private function resolveFont(size as Number) as Graphics.FontType {
        if (Graphics has :getVectorFont) {
            var vf = Graphics.getVectorFont({:face => FONT_FACE, :size => size});
            if (vf != null) {
                return vf;
            }
        }
        return Graphics.FONT_XTINY;
    }

    //! Build the rings to display, outermost first: a /60 minutes ring linked to
    //! the outer number dial, a bare steps arc in the middle (no number), and a
    //! /12 hours ring linked to the inner number dial. Either clock ring could
    //! take a negative value to wind the other way for a different metric, but
    //! for the clock both are positive.
    private function collectRings() as Array<Ring> {
        var clock = System.getClockTime();
        var minute = clock.min;
        var hour24 = clock.hour;
        var hour12 = hour24 % 12;
        if (hour12 == 0) {
            hour12 = 12;
        }

        var info = ActivityMonitor.getInfo();
        var steps = 0;
        var s = info.steps;
        if (s != null) {
            steps = s;
        }
        var stepGoal = 10000;
        var g = info.stepGoal;
        if (g != null && g > 0) {
            stepGoal = g;
        }

        return [
            new Ring(minute, 60, format2(minute), true),         // minutes -> outer /60 dial
            new Ring(steps, stepGoal, null, true),               // steps   -> bare arc, no number
            new Ring(hour24 % 12, 12, format2(hour12), false),   // hours   -> inner /12 dial
        ];
    }

    //! Two-digit number, e.g. 4 -> "04".
    private function format2(value as Number) as String {
        return value.format("%02d");
    }

    //! Draw one ring: a thin arc from 12 o'clock covering |fraction| of a turn
    //! (clockwise if positive, counter-clockwise if negative). If `label` is set,
    //! also draw a short radial tick from the arc's end to the number, printed on
    //! its dial (`labelRadius`). A null label leaves the arc bare.
    private function drawRing(
        dc as Graphics.Dc,
        cx as Numeric, cy as Numeric,
        arcRadius as Numeric, labelRadius as Numeric,
        font as Graphics.FontType, fontHeight as Numeric,
        fraction as Float, label as String?
    ) as Void {
        var startDeg = 90.0;
        var magnitude = (fraction < 0.0) ? -fraction : fraction;
        var sweep = magnitude * 360.0;
        if (sweep > 359.9) {
            sweep = 359.9;
        }

        var clockwise = (fraction >= 0.0);
        var endDeg = clockwise ? (startDeg - sweep) : (startDeg + sweep);
        var direction = clockwise ? Graphics.ARC_CLOCKWISE : Graphics.ARC_COUNTER_CLOCKWISE;
        if (endDeg < 0.0) {
            endDeg += 360.0;
        }
        if (endDeg >= 360.0) {
            endDeg -= 360.0;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(RING_PEN);
        if (sweep > 0.5) {
            dc.drawArc(cx, cy, arcRadius, direction, startDeg, endDeg);
        }

        // Black dots atop the arc at the cardinal quarter points (3/6/9 o'clock)
        // the arc has strictly passed, leaving a small gap there.
        var cardinals = [0.25, 0.5, 0.75];
        for (var k = 0; k < cardinals.size(); k++) {
            var c = cardinals[k];
            if (magnitude > c) {
                var cDeg = clockwise ? (startDeg - c * 360.0) : (startDeg + c * 360.0);
                var cRad = Math.toRadians(cDeg);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(
                    cx + arcRadius * Math.cos(cRad),
                    cy - arcRadius * Math.sin(cRad),
                    RING_PEN
                );
            }
        }

        var endRad = Math.toRadians(endDeg);
        var cosA = Math.cos(endRad);
        var sinA = Math.sin(endRad);

        // Bare arc (e.g. steps): no tick, no number.
        if (label == null) {
            return;
        }

        // Restore the drawing colour (the cardinal dots left it black).
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Radial tick from the arc's end to just short of the number.
        var gap = fontHeight / 2.0 + 2.0;
        var tickEndR = (labelRadius > arcRadius) ? (labelRadius - gap) : (labelRadius + gap);
        dc.drawLine(
            cx + arcRadius * cosA, cy - arcRadius * sinA,
            cx + tickEndR * cosA, cy - tickEndR * sinA
        );

        // Number on its dial at the arc's end angle.
        dc.drawText(
            cx + labelRadius * cosA, cy - labelRadius * sinA,
            font, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function onEnterSleep() as Void {
    }

    function onExitSleep() as Void {
    }

    //! Find the next sun event (today's sunrise, else today's sunset, else
    //! tomorrow's sunrise) and mark its local time on both clock rings: a
    //! coloured radial line at the minute position on the outer ring and at the
    //! hour position on the inner ring. Silently does nothing without a known
    //! location or during polar day/night.
    private function drawNextSunEvent(
        dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        minuteArcR as Numeric, hourArcR as Numeric
    ) as Void {
        var posInfo = Position.getInfo();
        var loc = posInfo.position;
        if (loc == null) {
            return;
        }
        var deg = loc.toDegrees();
        var lat = deg[0];
        var lon = deg[1];

        var now = Time.now().value().toDouble();
        var jd = SunCalc.julian(now);
        var today = SunCalc.riseSet(jd, lat, lon);
        if (today == null) {
            return;
        }
        var rise = today[:rise];
        var set = today[:set];
        if (rise == null || set == null) {
            return;
        }

        var eventUnix;
        var color;
        if (now < rise) {
            eventUnix = rise;
            color = SUNRISE_COLOR;
        } else if (now < set) {
            eventUnix = set;
            color = SUNSET_COLOR;
        } else {
            var tomorrow = SunCalc.riseSet(jd + 1.0, lat, lon);
            if (tomorrow == null) {
                return;
            }
            var nextRise = tomorrow[:rise];
            if (nextRise == null) {
                return;
            }
            eventUnix = nextRise;
            color = SUNRISE_COLOR;
        }

        var when = Gregorian.info(new Time.Moment(eventUnix.toNumber()), Time.FORMAT_SHORT);
        var eh = when.hour;
        var em = when.min;

        drawEventMarker(dc, cx, cy, minuteArcR, em / 60.0, color);
        drawEventMarker(dc, cx, cy, hourArcR, ((eh % 12) + em / 60.0) / 12.0, color);
    }

    //! A short coloured radial line crossing an arc at `fraction` of a turn
    //! clockwise from 12 o'clock, marking an event's position on that ring.
    private function drawEventMarker(
        dc as Graphics.Dc, cx as Numeric, cy as Numeric,
        arcRadius as Numeric, fraction as Float, color as Graphics.ColorValue
    ) as Void {
        var rad = Math.toRadians(90.0 - fraction * 360.0);
        var cosA = Math.cos(rad);
        var sinA = Math.sin(rad);
        var half = RING_PEN + 4.0;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(RING_PEN);
        dc.drawLine(
            cx + (arcRadius - half) * cosA, cy - (arcRadius - half) * sinA,
            cx + (arcRadius + half) * cosA, cy - (arcRadius + half) * sinA
        );
    }
}
