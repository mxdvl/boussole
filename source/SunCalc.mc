import Toybox.Lang;
import Toybox.Math;

//! Sunrise/sunset for a date and location. Pure math, no I/O. Longitude is
//! east-positive (as returned by `Position`), latitude north-positive. Times
//! are Unix seconds (UTC) until `nextEvent` converts them to a local time of
//! day.
//!
//! `riseSet` ports the day-number / mean-anomaly / equation-of-centre
//! algorithm from Astronomy Answers, "Position of the Sun", §2–§10:
//! https://www.aa.quae.nl/en/reken/zonpositie.html
//! Variable names match that page's terms, so the two can be read side by
//! side. For the underlying geometry (hour angle, declination, sign
//! conventions) see Wikipedia's "Sunrise equation":
//! https://en.wikipedia.org/wiki/Sunrise_equation
module SunCalc {

    const DEG = Math.PI / 180.0;  // radians per degree

    //! The next sunrise or sunset after `nowUnix` at (`latDeg`, `lonDeg`),
    //! whichever comes first, as a local minute of the day (0-1439).
    //! `utcOffset` is the local offset in seconds (DST included). Null when
    //! no future event exists in the neighbouring solar cycles (polar day/night).
    function nextEvent(nowUnix as Double, latDeg as Double, lonDeg as Double, utcOffset as Number) as Number? {
        var julianDate = julian(nowUnix);
        var soonest = null as Double?;
        var events = [:rise, :set];

        // A solar cycle can cross a UTC date boundary, especially far from
        // Greenwich or at high latitudes. Include the previous cycle so its
        // still-upcoming sunset is not lost at midnight; compare full UTC
        // timestamps before converting the winning event to local time.
        for (var offset = -1; offset <= 1; offset++) {
            var cycle = riseSet(julianDate + offset, latDeg, lonDeg);
            if (cycle == null) {
                continue;
            }
            for (var index = 0; index < events.size(); index++) {
                var moment = cycle[events[index]];
                if (moment == null || moment <= nowUnix) {
                    continue;
                }
                if (soonest == null || moment < soonest) {
                    soonest = moment;
                }
            }
        }
        return soonest != null ? localMinuteOfDay(soonest, utcOffset) : null;
    }

    //! Local minute of the day (0-1439) for a moment in Unix seconds.
    function localMinuteOfDay(unixSeconds as Double, utcOffset as Number) as Number {
        return (((unixSeconds.toLong() + utcOffset) / 60) % 1440).toNumber();
    }

    //! Julian date for a moment given as Unix seconds.
    function julian(unixSeconds as Double) as Double {
        return unixSeconds / 86400.0 + 2440587.5;
    }

    //! Sunrise and sunset for the solar cycle labelled by `julianDate`'s UTC
    //! calendar date. Either event may fall outside that UTC date. Follows
    //! Astronomy Answers §2–§10 (see module doc).
    //! Returns { :rise => Double, :set => Double } in Unix seconds, or null when
    //! the sun neither rises nor sets that day (polar day/night).
    function riseSet(julianDate as Double, latDeg as Double, lonDeg as Double) as Dictionary<Symbol, Double>? {
        // Julian dates start at noon; shift by half a day to label cycles
        // consistently at UTC midnight.
        var dayNumber = Math.floor(julianDate - 2451545.0 + 0.5).toDouble();

        // The reference uses west-positive longitude. Position supplies
        // east-positive longitude, so eastward locations have earlier UTC noon.
        var meanNoon = dayNumber - lonDeg / 360.0;
        var meanAnomaly = mod360(357.5291 + 0.98560028 * meanNoon);  // deg, §2
        var meanAnomalyRad = meanAnomaly * DEG;

        var equationOfCentre = 1.9148 * Math.sin(meanAnomalyRad)  // §3
            + 0.02 * Math.sin(2.0 * meanAnomalyRad)
            + 0.0003 * Math.sin(3.0 * meanAnomalyRad);
        // 282.9372 = 180 + 102.9372, the Sun's argument of perihelion (§4).
        var eclipticLongitude = mod360(meanAnomaly + equationOfCentre + 282.9372);  // deg, §5
        var eclipticLongitudeRad = eclipticLongitude * DEG;

        var transit = 2451545.0 + meanNoon  // §8
            + 0.0053 * Math.sin(meanAnomalyRad)
            - 0.0069 * Math.sin(2.0 * eclipticLongitudeRad);

        // 23.4397 deg is Earth's obliquity of the ecliptic (§4).
        var sinDeclination = Math.sin(eclipticLongitudeRad) * Math.sin(23.4397 * DEG);  // §6
        var cosDeclination = Math.sqrt(1.0 - sinDeclination * sinDeclination);

        var latRad = latDeg * DEG;
        // -0.833 deg is the Sun's altitude at sunrise/sunset once atmospheric
        // refraction and its apparent radius are accounted for (§10).
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
