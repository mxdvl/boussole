import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Where things go, derived only from the screen size. Tracks, from the rim
//! inwards:
//!
//!   stepsR  steps arc
//!   timeR   time arc and its 12 hour points; the minute tick reaches out to
//!           timeR + tickLen, the hour tick in to timeR - tickLen
//!
//! A position on a track is a fraction of a turn clockwise from 12 o'clock
//! (0.25 = 3 o'clock, 0.5 = 6 o'clock).
class Layout {

    public var cx as Float;
    public var cy as Float;

    public var pen as Float;         // arc + tick thickness, px
    public var numeralPen as Float;  // roman numeral stroke thickness, px
    public var numeralH as Float;    // roman numeral height, px
    public var tickLen as Float;

    public var stepsR as Float;
    public var timeR as Float;

    function initialize(width as Number, height as Number) {
        var screenR = (width < height ? width : height) / 2.0;

        cx = width / 2.0;
        cy = height / 2.0;

        pen = 3.0;
        numeralPen = 2.0;
        numeralH = screenR * 0.075;
        tickLen = screenR * 0.06;

        stepsR = screenR - pen - 4.0;
        timeR = stepsR - pen - tickLen - 8.0;
    }

    //! Screen x of the point `r` from the centre at `fraction` of a turn.
    function xAt(r as Float, fraction as Float) as Float {
        return (cx + r * Math.sin(fraction * 2.0 * Math.PI)).toFloat();
    }

    //! Screen y of the point `r` from the centre at `fraction` of a turn.
    function yAt(r as Float, fraction as Float) as Float {
        return (cy - r * Math.cos(fraction * 2.0 * Math.PI)).toFloat();
    }

    //! A radial stroke at `fraction` of a turn, from radius `fromR` to `toR`.
    function radial(
        fraction as Float, fromR as Float, toR as Float,
        color as Graphics.ColorType, width as Float
    ) as Shapes.Line {
        return new Shapes.Line(
            xAt(fromR, fraction), yAt(fromR, fraction),
            xAt(toR, fraction), yAt(toR, fraction),
            color, width
        );
    }
}
