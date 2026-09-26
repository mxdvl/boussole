import Toybox.Lang;
import Toybox.Position;
import Toybox.Test;
import Toybox.Time;
import Toybox.Weather;

//! Simulator-only regression tests; omitted from normal and release builds.
//! `nextEvent` now delegates the sunrise equation itself to Garmin's
//! `Weather.getSunrise`/`getSunset` (see SunCalc's doc comment), so these
//! cover the part still owned by this module: picking the soonest event
//! across the day boundary, and converting it to local time.
(:test)
module SunCalcTests {

    // 21 June 2026, noon UTC - a day either side of the northern-hemisphere
    // summer solstice, so long-day/no-set and short-day/no-rise cases are
    // unambiguous at moderately high latitudes.
    const JUNE_21_NOON = 1782043200;

    (:test)
    function localMinuteOfDayWrapsDate(logger as Test.Logger) as Boolean {
        var utc = SunCalc.localMinuteOfDay(JUNE_21_NOON, 0);
        var local = SunCalc.localMinuteOfDay(JUNE_21_NOON, -4 * 3600);
        return local == (utc - 240 + 1440) % 1440;
    }

    (:test)
    function advanceAfterSunset(logger as Test.Logger) as Boolean {
        // Reykjavik-ish: long summer evenings, sunset well after 22:00 local.
        var location = new Position.Location({
            :latitude => 64.1d, :longitude => -21.9d, :format => :degrees
        });
        var noon = new Time.Moment(JUNE_21_NOON);
        var sunset = Weather.getSunset(location, noon);
        if (sunset == null) { return false; }

        var justBefore = SunCalc.nextEvent(new Time.Moment(sunset.value() - 1), location, 0);
        var atSunset = SunCalc.nextEvent(sunset, location, 0);
        var justAfter = SunCalc.nextEvent(new Time.Moment(sunset.value() + 1), location, 0);
        logger.debug("Just before/at/after sunset: " + justBefore + "/" + atSunset + "/" + justAfter);

        if (atSunset == null || justAfter == null) { return false; }
        // Just before sunset, the next event is still that sunset.
        if (justBefore != SunCalc.localMinuteOfDay(sunset.value(), 0)) { return false; }
        // At and after sunset, the next event has moved on to the following sunrise.
        return justAfter == atSunset;
    }

    (:test)
    function polarDayHasNoEvent(logger as Test.Logger) as Boolean {
        // Well inside the Arctic Circle at the solstice: the sun does not set.
        var location = new Position.Location({
            :latitude => 78.0d, :longitude => 15.0d, :format => :degrees
        });
        return SunCalc.nextEvent(new Time.Moment(JUNE_21_NOON), location, 0) == null;
    }

    (:test)
    function polarNightHasNoEvent(logger as Test.Logger) as Boolean {
        // Same latitude, opposite hemisphere, same moment: the sun does not rise.
        var location = new Position.Location({
            :latitude => -78.0d, :longitude => 15.0d, :format => :degrees
        });
        return SunCalc.nextEvent(new Time.Moment(JUNE_21_NOON), location, 0) == null;
    }
}
