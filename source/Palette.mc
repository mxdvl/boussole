import Toybox.Graphics;

//! Named colours shared across rings.
module Palette {

    //! Craie ("chalk"): the main time arc and its hour bar.
    const CRAIE = Graphics.COLOR_WHITE;

    //! Encre ("ink"): the background, and the gaps cut across the arc at the quarters.
    const ENCRE = Graphics.COLOR_BLACK;

    //! Brume ("mist"): a soft teal-blue grey for everything secondary - hour
    //! points, numerals, the sun ring and the steps ring.
    const BRUME = 0x88A4AC;
}
