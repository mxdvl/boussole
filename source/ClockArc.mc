import Toybox.Graphics;
import Toybox.Lang;

//! One clock time drawn as an arc between its hour hand and its minute hand,
//! on the 12-hour scale, with a bar across the hour end. Used for the current
//! time and, in the same style, for sunrise and sunset.
//!
//! The hour hand is pinned to its hour point: it jumps from one point to the
//! next on the hour rather than creeping between them.
//!
//! The minute hand passes the pinned hour hand every 65 minutes (12:00, 1:05,
//! 2:10 ... 11:55). On even laps the arc runs clockwise from the hour to the
//! minute, so it fills from nothing to a full circle; on odd laps it runs from
//! the minute to the hour, so it empties again. The hour end steps by one
//! point each hour, and the short 11:55 lap ends with a reset at 12:00.
//!
//! - Hours: a bar across the arc at the hour hand's point, as thick as the
//!   arc and reaching both sides of it (a T on its side).
//! - Minutes: the arc's other end, unmarked.
module ClockArc {

    const TURN = 720;  // minutes in one turn of the hour hand
    const LAP = 65;    // minutes between the minute hand passing the pinned hour hand

    //! The arc and hour bar for `minuteOfDay` (0-1439) on the track of `radius`.
    function shapes(
        layout as Layout, radius as Float, minuteOfDay as Number, color as Graphics.ColorType
    ) as Array<Shapes.Shape> {
        var arcSpan = span(minuteOfDay);
        var hourHand = pinnedHour(minuteOfDay) / TURN.toFloat();
        return [
            new Shapes.Arc(layout.centreX, layout.centreY, radius, arcSpan[0], arcSpan[1], color, layout.arcWidth),
            layout.bar(hourHand, radius, layout.capReach, layout.arcWidth, color),
        ] as Array<Shapes.Shape>;
    }

    //! The hour hand in 1/720ths of a turn, pinned to the start of the hour.
    function pinnedHour(minuteOfDay as Number) as Number {
        return (minuteOfDay % TURN) / 60 * 60;
    }

    //! The arc between the hands as [start, sweep], fractions of a turn. Works
    //! in whole 1/720ths of a turn so the lap boundaries are exact.
    function span(minuteOfDay as Number) as [Float, Float] {
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

    //! `value` wrapped into [0, `size`).
    function wrap(value as Number, size as Number) as Number {
        return ((value % size) + size) % size;
    }
}
