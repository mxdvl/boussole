import Toybox.Graphics;
import Toybox.Lang;

//! Roman numerals drawn as straight strokes rather than a font. Only I, V and
//! X are needed. Glyphs are upright; widths and spacing are fractions of the
//! numeral's height.
module Numerals {

    const GAP = 0.3;  // space between glyphs

    //! Width of one glyph: I is a single vertical stroke.
    function glyphWidth(c as Char) as Float {
        return c == 'I' ? 0.0 : 0.6;
    }

    //! Total width in px of `text` drawn `h` px tall.
    function width(text as String, h as Float) as Float {
        var chars = text.toCharArray();
        var w = 0.0;
        for (var i = 0; i < chars.size(); i++) {
            w += glyphWidth(chars[i]);
        }
        return (w + (chars.size() - 1) * GAP) * h;
    }

    //! The strokes of `text`, upright and centred on (`x`, `y`), `h` px tall.
    function lines(
        text as String, x as Float, y as Float, h as Float,
        color as Graphics.ColorType, pen as Float
    ) as Array<Shapes.Shape> {
        var chars = text.toCharArray();
        var top = y - h / 2.0;
        var bottom = y + h / 2.0;
        var left = x - width(text, h) / 2.0;
        var out = [] as Array<Shapes.Shape>;

        for (var i = 0; i < chars.size(); i++) {
            var c = chars[i];
            var w = glyphWidth(c) * h;
            if (c == 'I') {
                out.add(new Shapes.Line(left, top, left, bottom, color, pen));
            } else if (c == 'V') {
                out.add(new Shapes.Line(left, top, left + w / 2.0, bottom, color, pen));
                out.add(new Shapes.Line(left + w, top, left + w / 2.0, bottom, color, pen));
            } else if (c == 'X') {
                out.add(new Shapes.Line(left, top, left + w, bottom, color, pen));
                out.add(new Shapes.Line(left + w, top, left, bottom, color, pen));
            }
            left += w + GAP * h;
        }
        return out;
    }
}
