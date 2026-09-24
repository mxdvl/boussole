import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Shared layout for every ring: the centre, the radius of each concentric
//! track, the fonts, and helpers to draw at a position on a track.
//!
//! Tracks, from the rim inwards:
//!
//!   stepsR        steps arc (bare progress arc)
//!   minuteLabelR  minutes number, reached by the time arc's outward tick
//!   timeR         time arc (12-hour scale) and its 12 hour points
//!   hourLabelR    hours number, reached by the time arc's inward tick
//!
//! A position on a track is a `fraction` of a turn, clockwise from 12 o'clock
//! (0.25 = 3 o'clock, 0.5 = 6 o'clock).
class Face {

    private const FONT_FACE = "RobotoCondensedBold";

    public var cx as Float;
    public var cy as Float;

    public var pen as Float;        // arc + tick thickness, px
    public var tickLen as Float;    // visible tick between an arc and a number
    public var labelGap as Float;   // clearance from a number's centre to its tick

    public var stepsR as Float;
    public var minuteLabelR as Float;
    public var timeR as Float;
    public var hourLabelR as Float;

    public var labelFont as Graphics.FontType;
    public var numeralFont as Graphics.FontType;

    function initialize(dc as Graphics.Dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var screenR = (width < height ? width : height) / 2.0;

        cx = width / 2.0;
        cy = height / 2.0;

        labelFont = resolveFont((screenR * 0.10).toNumber());
        numeralFont = resolveFont((screenR * 0.07).toNumber());
        var labelH = dc.getFontHeight(labelFont);

        pen = 3.0;
        tickLen = 12.0;
        labelGap = labelH / 2.0 + 2.0;

        stepsR = screenR - pen - 4.0;
        minuteLabelR = stepsR - pen - labelH / 2.0 - 6.0;
        timeR = minuteLabelR - labelGap - tickLen;
        hourLabelR = timeR - tickLen - labelGap;
    }

    //! Screen x of the point `r` from the centre at `fraction` of a turn.
    function xAt(r as Numeric, fraction as Numeric) as Numeric {
        return cx + r * Math.sin(fraction * 2.0 * Math.PI);
    }

    //! Screen y of the point `r` from the centre at `fraction` of a turn.
    function yAt(r as Numeric, fraction as Numeric) as Numeric {
        return cy - r * Math.cos(fraction * 2.0 * Math.PI);
    }

    //! Arc on track `r` from 12 o'clock clockwise to `fraction` (clamped to
    //! [0, 1]), in the current colour and pen width.
    function drawSweep(dc as Graphics.Dc, r as Numeric, fraction as Numeric) as Void {
        var sweep = fraction * 360.0;
        if (sweep < 0.5) {
            return;
        }
        if (sweep > 359.9) {
            sweep = 359.9;
        }
        var endDeg = 90.0 - sweep;
        if (endDeg < 0.0) {
            endDeg += 360.0;
        }
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 90.0, endDeg);
    }

    //! Radial line at `fraction` of a turn, from radius `fromR` to `toR`.
    function drawRadial(dc as Graphics.Dc, fraction as Numeric, fromR as Numeric, toR as Numeric) as Void {
        dc.drawLine(
            xAt(fromR, fraction), yAt(fromR, fraction),
            xAt(toR, fraction), yAt(toR, fraction)
        );
    }

    //! Text centred on track `r` at `fraction` of a turn.
    function drawTextAt(
        dc as Graphics.Dc, fraction as Numeric, r as Numeric,
        font as Graphics.FontType, text as String
    ) as Void {
        dc.drawText(
            xAt(r, fraction), yAt(r, fraction), font, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
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
}
