import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

//! Watch face that shows data as concentric partial rings. Each ring is an arc
//! from 12 o'clock whose length is `Ring.fraction()` of a full turn; positive
//! fractions sweep clockwise, negative ones counter-clockwise. The value is
//! printed in a bead at the arc's end.
//!
//! Add or reorder rings in `collectRings()` (outermost first). Layout sizes
//! itself to the number of rings, so more rings just get smaller.
class BoussoleView extends WatchUi.WatchFace {

    // Layout tuning (pixels unless noted).
    private const RING_PEN = 3.0;      // arc thickness
    private const EDGE_MARGIN = 6.0;   // gap from the screen rim to the outer bead
    private const RING_GAP = 10.0;     // radial spacing between adjacent rings
    private const BEAD_PAD = 2.0;      // padding around a label inside its bead
    private const GLYPH_RATIO = 0.72;  // usable glyph height / font line height

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

        var rings = collectRings();
        var font = Graphics.FONT_XTINY;
        var glyphHeight = dc.getFontHeight(font) * GLYPH_RATIO;

        // Bead sized snugly to each label.
        var beads = new Array<Float>[rings.size()];
        var maxBead = 0.0;
        for (var i = 0; i < rings.size(); i++) {
            var textWidth = dc.getTextWidthInPixels(rings[i].label, font);
            var span = (textWidth > glyphHeight) ? textWidth : glyphHeight;
            var bead = span / 2.0 + BEAD_PAD;
            beads[i] = bead;
            if (bead > maxBead) {
                maxBead = bead;
            }
        }

        // Pack the rings just inside the rim, close together.
        var ringStep = maxBead + RING_GAP;
        var radius = screenRadius - EDGE_MARGIN - maxBead;
        for (var i = 0; i < rings.size(); i++) {
            drawRing(
                dc, centerX, centerY, radius, RING_PEN, beads[i], font,
                rings[i].fraction(), rings[i].label
            );
            radius -= ringStep;
        }
    }

    //! Build the rings to display, outermost first. Adding a ring is one line.
    private function collectRings() as Array<Ring> {
        var clock = System.getClockTime();
        var minute = clock.min;
        var hour24 = clock.hour;
        var hour12 = hour24 % 12;
        if (hour12 == 0) {
            hour12 = 12;
        }
        // Hours ring: one clockwise sweep over the whole 24h day, jumping a
        // whole step each hour (5am at 5/24, 5pm at 17/24), never mid-hour.
        var hourValue = hour24;

        var steps = 0;
        var info = ActivityMonitor.getInfo();
        var currentSteps = info.steps;
        if (currentSteps != null) {
            steps = currentSteps;
        }

        return [
            new Ring(minute, 60, format2(minute)),      // minutes, 0-60
            new Ring(hourValue, 24, format2(hour12)),   // hours, full 24h clockwise sweep
            new Ring(steps, 12000, formatK(steps)),     // steps, full at 12K
        ];
    }

    //! Two-digit number, e.g. 4 -> "04".
    private function format2(value as Number) as String {
        return value.format("%02d");
    }

    //! Whole thousands with a K suffix, e.g. 3200 -> "3K".
    private function formatK(steps as Number) as String {
        return (steps / 1000).format("%d") + "K";
    }

    //! Draw one ring: an arc from 12 o'clock covering |fraction| of a full turn
    //! (clockwise if positive, counter-clockwise if negative), with `label` in a
    //! bead at its end. Purely a function of its arguments.
    private function drawRing(
        dc as Graphics.Dc,
        cx as Numeric, cy as Numeric, radius as Numeric,
        penWidth as Numeric, beadRadius as Numeric,
        font as Graphics.FontType,
        fraction as Float, label as String
    ) as Void {
        var startDeg = 90.0;
        var magnitude = (fraction < 0.0) ? -fraction : fraction;
        var sweep = magnitude * 360.0;
        if (sweep > 359.9) {
            sweep = 359.9;
        }

        var endDeg = startDeg;
        var direction = Graphics.ARC_CLOCKWISE;
        if (fraction < 0.0) {
            endDeg = startDeg + sweep;
            direction = Graphics.ARC_COUNTER_CLOCKWISE;
        } else {
            endDeg = startDeg - sweep;
        }
        if (endDeg < 0.0) {
            endDeg += 360.0;
        }
        if (endDeg >= 360.0) {
            endDeg -= 360.0;
        }

        dc.setPenWidth(penWidth);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (sweep > 0.5) {
            dc.drawArc(cx, cy, radius, direction, startDeg, endDeg);
        }

        // Marker at the 12 o'clock origin.
        var startRad = Math.toRadians(startDeg);
        dc.fillCircle(
            cx + radius * Math.cos(startRad),
            cy - radius * Math.sin(startRad),
            penWidth
        );

        // Bead + value at the arc's end.
        var endRad = Math.toRadians(endDeg);
        var endX = cx + radius * Math.cos(endRad);
        var endY = cy - radius * Math.sin(endRad);
        dc.fillCircle(endX, endY, beadRadius);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            endX, endY, font, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function onEnterSleep() as Void {
    }

    function onExitSleep() as Void {
    }
}
