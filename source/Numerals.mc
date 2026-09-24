import Toybox.Graphics;
import Toybox.Lang;

//! Roman numerals drawn as straight strokes rather than a font. Only I, V and
//! X are needed. Glyphs are upright; widths and spacing are fractions of the
//! numeral's height.
module Numerals {

    const SPACING = 0.3;  // space between glyphs

    //! Width of one glyph: I is a single vertical stroke.
    function glyphWidth(glyph as Char) as Float {
        return glyph == 'I' ? 0.0 : 0.6;
    }

    //! Total width in px of `text` drawn `height` px tall.
    function width(text as String, height as Float) as Float {
        var glyphs = text.toCharArray();
        var total = 0.0;
        for (var index = 0; index < glyphs.size(); index++) {
            total += glyphWidth(glyphs[index]);
        }
        return (total + (glyphs.size() - 1) * SPACING) * height;
    }

    //! The strokes of `text`, upright and centred on (`centreX`, `centreY`),
    //! `height` px tall.
    function lines(
        text as String, centreX as Float, centreY as Float, height as Float,
        color as Graphics.ColorType, penWidth as Float
    ) as Array<Shapes.Shape> {
        var glyphs = text.toCharArray();
        var top = centreY - height / 2.0;
        var bottom = centreY + height / 2.0;
        var left = centreX - width(text, height) / 2.0;
        var strokes = [] as Array<Shapes.Shape>;

        for (var index = 0; index < glyphs.size(); index++) {
            var glyph = glyphs[index];
            var right = left + glyphWidth(glyph) * height;
            var middle = (left + right) / 2.0;
            if (glyph == 'I') {
                strokes.add(new Shapes.Line(left, top, left, bottom, color, penWidth));
            } else if (glyph == 'V') {
                strokes.add(new Shapes.Line(left, top, middle, bottom, color, penWidth));
                strokes.add(new Shapes.Line(right, top, middle, bottom, color, penWidth));
            } else if (glyph == 'X') {
                strokes.add(new Shapes.Line(left, top, right, bottom, color, penWidth));
                strokes.add(new Shapes.Line(right, top, left, bottom, color, penWidth));
            }
            left = right + SPACING * height;
        }
        return strokes;
    }
}
