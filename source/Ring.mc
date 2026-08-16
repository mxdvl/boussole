import Toybox.Lang;

//! One ring's data: how full it is (`value` out of a `max` magnitude), the text
//! to show, and which number track its tick links to. Pure data + a `fraction`
//! accessor; no drawing logic.
//!
//! `value` is signed: positive fills clockwise from 12 o'clock, negative fills
//! the same amount counter-clockwise. `max` is the magnitude of a full turn, so
//! the usable range is [-max, +max].
//!
//! `tickOutward` selects where the value is printed: true -> the outer number
//! track (near the rim), false -> the inner track (near the center). When
//! `label` is null the ring is a bare arc: no tick, no number (e.g. steps).
//!
//! Examples:
//!   new Ring(minute, 60, "28", true)     // minutes -> outer 60 track
//!   new Ring(steps, 10000, null, true)   // steps   -> bare arc, no number
//!   new Ring(hour24, 24, "11", false)    // hours   -> inner 12 track
class Ring {
    public var value as Numeric;
    public var max as Numeric;
    public var label as String?;
    public var tickOutward as Boolean;

    function initialize(value as Numeric, max as Numeric, label as String?, tickOutward as Boolean) {
        self.value = value;
        self.max = max;
        self.label = label;
        self.tickOutward = tickOutward;
    }

    //! Signed fill amount, clamped to [-1, 1]. Sign selects arc direction.
    function fraction() as Float {
        var f = value.toFloat() / max.toFloat();
        if (f > 1.0) {
            return 1.0;
        }
        if (f < -1.0) {
            return -1.0;
        }
        return f;
    }
}
