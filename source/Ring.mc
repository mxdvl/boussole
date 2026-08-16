import Toybox.Lang;

//! One ring's data: how full it is (`value` out of a `max` magnitude) and the
//! text to show at the arc's end. Pure data + a `fraction` accessor; no drawing
//! logic.
//!
//! `value` is signed: a positive value fills clockwise from 12 o'clock, a
//! negative value fills the same amount counter-clockwise. `max` is the
//! magnitude that corresponds to a full turn, so the usable range is
//! [-max, +max].
//!
//! Examples:
//!   new Ring(minute, 60, "04")       // minutes on a 0-60 scale
//!   new Ring(hour * 5, 60, "11")     // hours scaled x5 onto the same 0-60
//!   new Ring(steps, 12000, "3K")     // steps, full ring at 12K
//!   new Ring(tempC, 40, "-12")       // temperature, negative winds back
class Ring {
    public var value as Numeric;
    public var max as Numeric;
    public var label as String;

    function initialize(value as Numeric, max as Numeric, label as String) {
        self.value = value;
        self.max = max;
        self.label = label;
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
