import Toybox.Graphics;
import Toybox.Lang;

//! The clock: a single arc between the hour hand and the minute hand, on the
//! 12-hour scale. The hour hand is pinned to its hour point: it jumps from one
//! point to the next on the hour rather than creeping between them.
//!
//! The minute hand passes the pinned hour hand every 65 minutes (12:00, 1:05,
//! 2:10 ... 11:55). On even laps the arc runs clockwise from the hour to the
//! minute, so it fills from nothing to a full circle; on odd laps it runs from
//! the minute to the hour, so it empties again. The hour end steps by one
//! point each hour, and the short 11:55 lap ends with a reset at 12:00.
//!
//! - Hours: an inward tick at the hour hand's point.
//! - Minutes: an outward tick at the minute hand's position.
//! - 12 hour points along the track. Points under the arc are cut out of it
//!   as small notches; the others are teal-grey dots.
//! - XII, III, VI and IX in the same teal-grey, just inside the track so the
//!   arc runs past them uninterrupted.
//! - The next sunrise (orange) or sunset (blue) crosses the track in colour.
module TimeRing {

    const TURN = 720;  // minutes in one turn of the hour hand
    const LAP = 65;    // minutes between the minute hand passing the pinned hour hand

    const ARC_COLOR = Graphics.COLOR_WHITE;
    const MARKING_COLOR = 0x88A4AC;  // teal-grey, for hour points and numerals
    const SUNRISE_COLOR = Graphics.COLOR_ORANGE;
    const SUNSET_COLOR = Graphics.COLOR_BLUE;

    //! Everything on the time track for local time `minuteOfDay` (0-1439).
    function scene(layout as Layout, minuteOfDay as Number, sun as SunCalc.Event?) as Array<Shapes.Shape> {
        var hourHand = pinnedHour(minuteOfDay) / TURN.toFloat();
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
        shapes.addAll(hourPoints(layout, start, sweep));
        shapes.addAll(numerals(layout));
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

    //! The hour hand in 1/720ths of a turn, pinned to the start of the hour.
    function pinnedHour(minuteOfDay as Number) as Number {
        return (minuteOfDay % TURN) / 60 * 60;
    }

    //! The arc between the hands as [start, sweep], fractions of a turn. Works
    //! in whole 1/720ths of a turn so the lap boundaries are exact.
    function arcSpan(minuteOfDay as Number) as [Float, Float] {
        var hourHand = pinnedHour(minuteOfDay);
        var minuteHand = (minuteOfDay % 60) * 12;
        var lap = (minuteOfDay % TURN) / LAP;

        if (lap % 2 == 0) {
            // Filling: hour -> minute.
            return [hourHand / TURN.toFloat(), wrap(minuteHand - hourHand, TURN) / TURN.toFloat()];
        }
        // Emptying: minute -> hour. At the lap's first instant the hands meet
        // and the arc is still full.
        var sweep = wrap(hourHand - minuteHand, TURN);
        return [minuteHand / TURN.toFloat(), (sweep == 0 ? TURN : sweep) / TURN.toFloat()];
    }

    //! The 12 hour points on the track: notches where the arc covers them,
    //! dots elsewhere.
    function hourPoints(layout as Layout, start as Float, sweep as Float) as Array<Shapes.Shape> {
        var shapes = [] as Array<Shapes.Shape>;
        for (var hour = 0; hour < 12; hour++) {
            var position = hour / 12.0;
            var pointX = layout.xAt(layout.timeRadius, position);
            var pointY = layout.yAt(layout.timeRadius, position);
            if (isWithin(position, start, sweep)) {
                shapes.add(new Shapes.Dot(pointX, pointY, layout.penWidth, Graphics.COLOR_BLACK));
            } else {
                shapes.add(new Shapes.Dot(pointX, pointY, layout.penWidth / 2.0, MARKING_COLOR));
            }
        }
        return shapes;
    }

    //! XII, III, VI and IX on the numeral track.
    function numerals(layout as Layout) as Array<Shapes.Shape> {
        var shapes = [] as Array<Shapes.Shape>;
        var texts = ["XII", "III", "VI", "IX"];
        for (var quarter = 0; quarter < texts.size(); quarter++) {
            var position = quarter / 4.0;
            shapes.addAll(Numerals.lines(
                texts[quarter],
                layout.xAt(layout.numeralRadius, position),
                layout.yAt(layout.numeralRadius, position),
                layout.numeralHeight, MARKING_COLOR, layout.numeralPenWidth
            ));
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

    //! Whether `position` lies on the arc from `start` clockwise for `sweep`.
    function isWithin(position as Float, start as Float, sweep as Float) as Boolean {
        var offset = position - start;
        if (offset < 0.0) {
            offset += 1.0;
        }
        return offset < sweep;
    }

    //! `value` wrapped into [0, `size`).
    function wrap(value as Number, size as Number) as Number {
        return ((value % size) + size) % size;
    }
}
