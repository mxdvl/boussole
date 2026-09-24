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
        var hourHand = (minuteOfDay % TURN) / TURN.toFloat();
        var minuteHand = (minuteOfDay % 60) / 60.0;
        var span = arcSpan(minuteOfDay);
        var start = span[0];
        var sweep = span[1];

        var shapes = [
            new Shapes.Arc(
                layout.centreX, layout.centreY, layout.timeRadius, start, sweep,
                ARC_COLOR, layout.penWidth
            ),
        ] as Array<Shapes.Shape>;
        shapes.addAll(hourPoints(layout, start, sweep, hourHand, minuteHand));
        if (sun != null) {
            shapes.add(sunMarker(layout, sun));
        }
        shapes.add(layout.radial(
            hourHand, layout.timeRadius - layout.tickLength, layout.timeRadius,
            ARC_COLOR, layout.penWidth
        ));
        shapes.add(layout.radial(
            minuteHand, layout.timeRadius, layout.timeRadius + layout.tickLength,
            ARC_COLOR, layout.penWidth
        ));
        return shapes;
    }

    //! The arc between the hands as [start, sweep], fractions of a turn. Works
    //! in whole 1/720ths of a turn (one minute of the hour hand) so the lap
    //! boundaries are exact.
    function arcSpan(minuteOfDay as Number) as [Float, Float] {
        var hourHand = minuteOfDay % TURN;
        var minuteHand = (minuteOfDay % 60) * 12;
        var lap = minuteOfDay * 11 / TURN;

        if (lap % 2 == 0) {
            // Filling: hour -> minute.
            return [hourHand / TURN.toFloat(), wrap(minuteHand - hourHand, TURN) / TURN.toFloat()];
        }
        // Emptying: minute -> hour. At the lap's first instant the hands meet
        // and the arc is still full.
        var sweep = wrap(hourHand - minuteHand, TURN);
        return [minuteHand / TURN.toFloat(), (sweep == 0 ? TURN : sweep) / TURN.toFloat()];
    }

    //! The 12 hour points. A numeral sits on a black box that cuts through the
    //! arc; it gives way to a plain point when either tick lands on it.
    function hourPoints(
        layout as Layout, start as Float, sweep as Float,
        hourHand as Float, minuteHand as Float
    ) as Array<Shapes.Shape> {
        var shapes = [] as Array<Shapes.Shape>;
        var padding = layout.penWidth;

        for (var hour = 0; hour < 12; hour++) {
            var position = hour / 12.0;
            var pointX = layout.xAt(layout.timeRadius, position);
            var pointY = layout.yAt(layout.timeRadius, position);
            var text = numeral(hour);

            if (text != null) {
                var textWidth = Numerals.width(text, layout.numeralHeight);
                var clearance = (textWidth / 2.0 + padding) / (2.0 * Math.PI * layout.timeRadius);
                if (!isNear(position, hourHand, clearance) && !isNear(position, minuteHand, clearance)) {
                    shapes.add(new Shapes.Box(
                        pointX, pointY,
                        textWidth + 2.0 * padding, layout.numeralHeight + 2.0 * padding,
                        Graphics.COLOR_BLACK
                    ));
                    shapes.addAll(Numerals.lines(
                        text, pointX, pointY, layout.numeralHeight,
                        ARC_COLOR, layout.numeralPenWidth
                    ));
                    continue;
                }
            }

            if (isWithin(position, start, sweep)) {
                shapes.add(new Shapes.Dot(pointX, pointY, layout.penWidth, Graphics.COLOR_BLACK));
            } else {
                shapes.add(new Shapes.Dot(pointX, pointY, layout.penWidth / 2.0, POINT_COLOR));
            }
        }
        return shapes;
    }

    //! A short coloured stroke across the track at the sun event's time.
    function sunMarker(layout as Layout, sun as SunCalc.Event) as Shapes.Line {
        var position = (sun.minuteOfDay % TURN) / TURN.toFloat();
        var halfLength = layout.penWidth + 4.0;
        var color = sun.isSunrise ? SUNRISE_COLOR : SUNSET_COLOR;
        return layout.radial(
            position, layout.timeRadius - halfLength, layout.timeRadius + halfLength,
            color, layout.penWidth
        );
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

    //! Whether `position` lies on the arc from `start` clockwise for `sweep`.
    function isWithin(position as Float, start as Float, sweep as Float) as Boolean {
        var offset = position - start;
        if (offset < 0.0) {
            offset += 1.0;
        }
        return offset < sweep;
    }

    //! Whether two positions are within `clearance` of each other, either way
    //! round the dial.
    function isNear(first as Float, second as Float, clearance as Float) as Boolean {
        var distance = first - second;
        if (distance < 0.0) {
            distance = -distance;
        }
        if (distance > 0.5) {
            distance = 1.0 - distance;
        }
        return distance < clearance;
    }

    //! `value` wrapped into [0, `size`).
    function wrap(value as Number, size as Number) as Number {
        return ((value % size) + size) % size;
    }
}
