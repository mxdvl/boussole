import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
import Toybox.Weather;

//! Next sunrise/sunset for a moment and location, via Garmin's on-device
//! `Weather.getSunrise`/`getSunset` (Connect IQ API Level 3.3.0), which
//! replaced this module's own sunrise-equation port. Weather's methods take
//! a location and a day and return that one event as a `Time.Moment`;
//! `nextEvent` asks for both events on `now`'s day and the following day,
//! then picks whichever is soonest still ahead of `now`.
module SunCalc {

    //! The next sunrise or sunset after `now`, whichever comes first, as a
    //! local minute of the day (0-1439). `utcOffset` is the local offset in
    //! seconds (DST included). Null when Weather has neither event for
    //! either day (polar day/night) or can't compute one for this location.
    function nextEvent(now as Time.Moment, location as Position.Location, utcOffset as Number) as Number? {
        var tomorrow = now.add(new Time.Duration(86400));
        var candidates = [
            Weather.getSunrise(location, now),
            Weather.getSunset(location, now),
            Weather.getSunrise(location, tomorrow),
            Weather.getSunset(location, tomorrow),
        ] as Array<Time.Moment?>;

        var nowSeconds = now.value();
        var soonest = null as Number?;
        for (var index = 0; index < candidates.size(); index++) {
            var moment = candidates[index];
            if (moment == null) {
                continue;
            }
            var seconds = moment.value();
            if (seconds <= nowSeconds) {
                continue;
            }
            if (soonest == null || seconds < soonest) {
                soonest = seconds;
            }
        }
        return soonest != null ? localMinuteOfDay(soonest, utcOffset) : null;
    }

    //! Local minute of the day (0-1439) for a moment given in Unix seconds.
    function localMinuteOfDay(unixSeconds as Number, utcOffset as Number) as Number {
        return ((unixSeconds + utcOffset) / 60) % 1440;
    }
}
