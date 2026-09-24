import Toybox.Lang;
import Toybox.Math;

//! Sunrise/sunset for a date and location, via the standard "sunrise equation"
//! (NOAA/Wikipedia). Pure math, no I/O. Longitude is east-positive (as returned
//! by `Position`), latitude north-positive. Times are Unix seconds (UTC) until
//! `upcoming` converts them to local times of day.
module SunCalc {

    const DEG = Math.PI / 180.0;  // radians per degree

    //! The upcoming sunrise and sunset as local times of day (minutes,
    //! 0-1439). Either is null when the sun doesn't rise or set (polar
    //! day/night).
    class Times {
        public var sunrise as Number?;
        public var sunset as Number?;

        function initialize(sunrise as Number?, sunset as Number?) {
            self.sunrise = sunrise;
            self.sunset = sunset;
        }
    }

    //! The next sunrise and the next sunset after `nowUnix` at (`latDeg`,
    //! `lonDeg`): today's if still to come, else tomorrow's. `utcOffset` is the
    //! local offset in seconds (DST included), used for the time of day.
    function upcoming(nowUnix as Double, latDeg as Double, lonDeg as Double, utcOffset as Number) as Times {
        var julianDate = julian(nowUnix);
        var today = riseSet(julianDate, latDeg, lonDeg);
        var tomorrow = riseSet(julianDate + 1.0, latDeg, lonDeg);
        return new Times(
            nextOf(:rise, nowUnix, today, tomorrow, utcOffset),
            nextOf(:set, nowUnix, today, tomorrow, utcOffset)
        );
    }

    //! Today's `event` (:rise or :set) if it is still to come, else
    //! tomorrow's, as a local minute of the day.
    function nextOf(
        event as Symbol, nowUnix as Double,
        today as Dictionary<Symbol, Double>?, tomorrow as Dictionary<Symbol, Double>?,
        utcOffset as Number
    ) as Number? {
        if (today != null) {
            var moment = today[event];
            if (moment != null && nowUnix < moment) {
                return localMinuteOfDay(moment, utcOffset);
            }
        }
        if (tomorrow != null) {
            var moment = tomorrow[event];
            if (moment != null) {
                return localMinuteOfDay(moment, utcOffset);
            }
        }
        return null;
    }

    //! Local minute of the day (0-1439) for a moment in Unix seconds.
    function localMinuteOfDay(unixSeconds as Double, utcOffset as Number) as Number {
        return (((unixSeconds.toLong() + utcOffset) / 60) % 1440).toNumber();
    }

    //! Julian date for a moment given as Unix seconds.
    function julian(unixSeconds as Double) as Double {
        return unixSeconds / 86400.0 + 2440587.5;
    }

    //! Sunrise and sunset for the solar day containing `julianDate`.
    //! Returns { :rise => Double, :set => Double } in Unix seconds, or null when
    //! the sun neither rises nor sets that day (polar day/night).
    function riseSet(julianDate as Double, latDeg as Double, lonDeg as Double) as Dictionary<Symbol, Double>? {
        var dayNumber = ((julianDate - 2451545.0 + 0.0008) + 0.5).toNumber().toDouble();

        var meanNoon = dayNumber + lonDeg / 360.0;
        var meanAnomaly = mod360(357.5291 + 0.98560028 * meanNoon);  // deg
        var meanAnomalyRad = meanAnomaly * DEG;

        var equationOfCentre = 1.9148 * Math.sin(meanAnomalyRad)
            + 0.02 * Math.sin(2.0 * meanAnomalyRad)
            + 0.0003 * Math.sin(3.0 * meanAnomalyRad);
        var eclipticLongitude = mod360(meanAnomaly + equationOfCentre + 282.9372);  // deg
        var eclipticLongitudeRad = eclipticLongitude * DEG;

        var transit = 2451545.0 + meanNoon
            + 0.0053 * Math.sin(meanAnomalyRad)
            - 0.0069 * Math.sin(2.0 * eclipticLongitudeRad);

        var sinDeclination = Math.sin(eclipticLongitudeRad) * Math.sin(23.4397 * DEG);
        var cosDeclination = Math.sqrt(1.0 - sinDeclination * sinDeclination);

        var latRad = latDeg * DEG;
        var cosHourAngle = (Math.sin(-0.833 * DEG) - Math.sin(latRad) * sinDeclination)
            / (Math.cos(latRad) * cosDeclination);
        if (cosHourAngle > 1.0 || cosHourAngle < -1.0) {
            return null;  // sun stays down / up all day
        }

        var hourAngle = Math.acos(cosHourAngle) / DEG;  // deg
        var riseJulian = transit - hourAngle / 360.0;
        var setJulian = transit + hourAngle / 360.0;

        return {
            :rise => (riseJulian - 2440587.5) * 86400.0,
            :set => (setJulian - 2440587.5) * 86400.0,
        };
    }

    //! Reduce an angle in degrees to [0, 360).
    function mod360(degrees as Double) as Double {
        var reduced = degrees - (degrees / 360.0).toNumber() * 360.0;
        if (reduced < 0.0) {
            reduced += 360.0;
        }
        return reduced;
    }
}
