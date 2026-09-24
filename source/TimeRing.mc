import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The clock: a single arc between the hour hand and the minute hand, on the
//! 12-hour scale.
//!
//! The minute hand laps the hour hand every 12/11 h (~65.5 min). On even laps
//! the arc runs clockwise from the hour to the minute, so it fills from nothing
//! to a full circle; on odd laps it runs from the minute to the hour, so it
//! empties again. The laps start at midnight (22 per day), so the arc never
//! jumps.
//!
//! - Hours: an inward tick at the hour hand's position.
//! - Minutes: an outward tick at the minute hand's position.
//! - 12 hour points along the track: XII, III, VI and IX as stroked numerals
//!   that cut through the arc (unless a tick lands on one), dots elsewhere.
//!   Dots under the arc are cut out of it as small notches.
//! - The next sunrise (orange) or sunset (blue) crosses the track in colour.
module TimeRing {

    const TURN = 720;  // minutes in one turn of the hour hand

    const ARC_COLOR = Graphics.COLOR_WHITE;
    const POINT_COLOR = Graphics.COLOR_LT_GRAY;
    const SUNRISE_COLOR = Graphics.COLOR_ORANGE;
    const SUNSET_COLOR = Graphics.COLOR_BLUE;

    //! Everything on the time track for local time `minuteOfDay` (0-1439).
    function scene(layout as Layout, minuteOfDay as Number, sun as SunCalc.Event?) as Array<Shapes.Shape> {
        var hourAt = (minuteOfDay % TURN) / TURN.toFloat();
        var minuteAt = (minuteOfDay % 60) / 60.0;
        var span = arcSpan(minuteOfDay);

        var out = [
            new Shapes.Arc(layout.cx, layout.cy, layout.timeR, span[0], span[1], ARC_COLOR, layout.pen),
        ] as Array<Shapes.Shape>;
        out.addAll(hourPoints(layout, span[0], span[1], hourAt, minuteAt));
        if (sun != null) {
            out.add(sunMarker(layout, sun));
        }
        out.add(layout.radial(hourAt, layout.timeR, layout.timeR - layout.tickLen, ARC_COLOR, layout.pen));
        out.add(layout.radial(minuteAt, layout.timeR, layout.timeR + layout.tickLen, ARC_COLOR, layout.pen));
        return out;
    }

    //! The arc between the hands as [start, sweep], fractions of a turn. Works
    //! in whole 1/720ths of a turn (one minute of the hour hand) so the lap
    //! boundaries are exact.
    function arcSpan(minuteOfDay as Number) as [Float, Float] {
        var hour = minuteOfDay % TURN;
        var minute = (minuteOfDay % 60) * 12;
        var lap = minuteOfDay * 11 / TURN;

        if (lap % 2 == 0) {
            // Filling: hour -> minute.
            return [hour / TURN.toFloat(), mod(minute - hour, TURN) / TURN.toFloat()];
        }
        // Emptying: minute -> hour. At the lap's first instant the hands meet
        // and the arc is still full.
        var sweep = mod(hour - minute, TURN);
        return [minute / TURN.toFloat(), (sweep == 0 ? TURN : sweep) / TURN.toFloat()];
    }

    //! The 12 hour points. A numeral sits on a black box that cuts through the
    //! arc; it gives way to a plain point when either tick lands on it.
    function hourPoints(
        layout as Layout, start as Float, sweep as Float,
        hourAt as Float, minuteAt as Float
    ) as Array<Shapes.Shape> {
        var out = [] as Array<Shapes.Shape>;
        var pad = layout.pen;

        for (var k = 0; k < 12; k++) {
            var f = k / 12.0;
            var x = layout.xAt(layout.timeR, f);
            var y = layout.yAt(layout.timeR, f);
            var text = numeral(k);

            if (text != null) {
                var w = Numerals.width(text, layout.numeralH);
                var tolerance = (w / 2.0 + pad) / (2.0 * Math.PI * layout.timeR);
                if (!isNear(f, hourAt, tolerance) && !isNear(f, minuteAt, tolerance)) {
                    out.add(new Shapes.Box(x, y, w + 2.0 * pad, layout.numeralH + 2.0 * pad, Graphics.COLOR_BLACK));
                    out.addAll(Numerals.lines(text, x, y, layout.numeralH, ARC_COLOR, layout.numeralPen));
                    continue;
                }
            }

            if (isWithin(f, start, sweep)) {
                out.add(new Shapes.Dot(x, y, layout.pen, Graphics.COLOR_BLACK));
            } else {
                out.add(new Shapes.Dot(x, y, layout.pen / 2.0, POINT_COLOR));
            }
        }
        return out;
    }

    //! A short coloured stroke across the track at the sun event's time.
    function sunMarker(layout as Layout, sun as SunCalc.Event) as Shapes.Line {
        var at = (sun.minuteOfDay % TURN) / TURN.toFloat();
        var half = layout.pen + 4.0;
        var color = sun.isSunrise ? SUNRISE_COLOR : SUNSET_COLOR;
        return layout.radial(at, layout.timeR - half, layout.timeR + half, color, layout.pen);
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

    //! Whether position `f` lies on the arc from `start` clockwise for `sweep`.
    function isWithin(f as Float, start as Float, sweep as Float) as Boolean {
        var d = f - start;
        if (d < 0.0) {
            d += 1.0;
        }
        return d < sweep;
    }

    //! Whether two positions are within `tolerance` of each other, either way
    //! round the dial.
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

    //! `a` modulo `n`, always in [0, n).
    function mod(a as Number, n as Number) as Number {
        return ((a % n) + n) % n;
    }
}
