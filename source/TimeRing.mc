import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

//! The clock: a single arc on the 12-hour scale, filled clockwise from
//! 12 o'clock to the current time (the path an hour hand has travelled).
//!
//! - Hours: an inward tick at the arc's end, pointing to the hour printed on
//!   the inner track (`face.hourLabelR`).
//! - Minutes: an outward tick at minute/60 of a turn, pointing to the minutes
//!   printed on the outer track (`face.minuteLabelR`).
//! - 12 hour points along the track: XII, III, VI and IX as numerals (unless a
//!   tick lands on one), dots elsewhere. Points the arc has passed are cut out
//!   of it as small gaps.
//! - The next sunrise (orange) or sunset (blue) crosses the track in colour.
module TimeRing {

    const SUNRISE_COLOR = Graphics.COLOR_ORANGE;
    const SUNSET_COLOR = Graphics.COLOR_BLUE;
    const POINT_COLOR = Graphics.COLOR_LT_GRAY;

    function draw(dc as Graphics.Dc, face as Face) as Void {
        var clock = System.getClockTime();
        var hour = clock.hour % 12;
        var minute = clock.min;
        var hourFraction = (hour + minute / 60.0) / 12.0;
        var minuteFraction = minute / 60.0;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(face.pen);
        face.drawSweep(dc, face.timeR, hourFraction);

        drawHourPoints(dc, face, hourFraction, minuteFraction);
        drawSunEvent(dc, face);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(face.pen);

        // Hours: inward tick from the arc's end to the inner track.
        var hourText = (hour == 0 ? 12 : hour).format("%02d");
        face.drawRadial(dc, hourFraction, face.timeR, face.hourLabelR + face.labelGap);
        face.drawTextAt(dc, hourFraction, face.hourLabelR, face.labelFont, hourText);

        // Minutes: outward tick from the track to the outer track.
        face.drawRadial(dc, minuteFraction, face.timeR, face.minuteLabelR - face.labelGap);
        face.drawTextAt(dc, minuteFraction, face.minuteLabelR, face.labelFont, minute.format("%02d"));
    }

    //! The 12 hour points on the time track. A numeral is drawn over a black
    //! box so it cuts through the arc; it gives way to a plain point when either
    //! tick would run into it.
    function drawHourPoints(
        dc as Graphics.Dc, face as Face,
        hourFraction as Float, minuteFraction as Float
    ) as Void {
        for (var k = 0; k < 12; k++) {
            var f = k / 12.0;
            var text = numeral(k);

            if (text != null) {
                var halfWidth = dc.getTextWidthInPixels(text, face.numeralFont) / 2.0 + face.pen;
                var tolerance = halfWidth / (2.0 * Math.PI * face.timeR);
                if (!isNear(f, hourFraction, tolerance) && !isNear(f, minuteFraction, tolerance)) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                    face.drawTextAt(dc, f, face.timeR, face.numeralFont, text);
                    continue;
                }
            }

            if (f < hourFraction) {
                // Passed: a notch cut out of the arc.
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(face.xAt(face.timeR, f), face.yAt(face.timeR, f), face.pen);
            } else {
                dc.setColor(POINT_COLOR, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(face.xAt(face.timeR, f), face.yAt(face.timeR, f), face.pen / 2.0);
            }
        }
    }

    //! Roman numeral for the quarter hours, null for the others.
    function numeral(hour as Number) as String? {
        switch (hour) {
            case 0: return "XII";
            case 3: return "III";
            case 6: return "VI";
            case 9: return "IX";
            default: return null;
        }
    }

    //! Whether two positions (fractions of a turn) are within `tolerance` of
    //! each other, going either way round the dial.
    function isNear(a as Float, b as Float, tolerance as Float) as Boolean {
        var d = a - b;
        if (d < 0.0) {
            d = -d;
        }
        if (d > 0.5) {
            d = 1.0 - d;
        }
        return d < tolerance;
    }

    //! A short coloured line across the time track at the next sun event.
    function drawSunEvent(dc as Graphics.Dc, face as Face) as Void {
        var event = SunEvent.next();
        if (event == null) {
            return;
        }
        var when = Gregorian.info(event.moment, Time.FORMAT_SHORT);
        var fraction = ((when.hour % 12) + when.min / 60.0) / 12.0;
        var half = face.pen + 4.0;

        dc.setColor(event.isSunrise ? SUNRISE_COLOR : SUNSET_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(face.pen);
        face.drawRadial(dc, fraction, face.timeR - half, face.timeR + half);
    }
}
