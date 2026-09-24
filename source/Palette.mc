import Toybox.Graphics;

//! Named colours shared across rings.
module Palette {

    //! Craie ("chalk"): the main time arc and its hour bar.
    const CRAIE = Graphics.COLOR_WHITE;

    //! Encre ("ink"): the background, and the quarter notches cut into the arc.
    const ENCRE = Graphics.COLOR_BLACK;

    //! Brume ("mist"): a soft teal-blue grey for everything secondary - hour
    //! points, numerals, and the sun ring.
    const BRUME = 0x88A4AC;
}
