pragma Singleton
import QtQuick
import Quickshell
import qs.config
import "../utils/Log.js" as Log

Singleton {
    id: weather

    property bool isActive: false
    property bool isReady: false
    property real temperature: 0
    property real rainChance: 0
    property string kind: "cloudy"
    property var days: []
    property real fetchedAt: 0
    property var place: null

    readonly property string location: Config.data.weather.location
    readonly property int forecastDays: 3

    function kindOf(code) {
        if (code === 0)
            return "clear"
        if (code <= 2)
            return "partly"
        if (code === 3)
            return "cloudy"
        if (code === 45 || code === 48)
            return "fog"
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "snow"
        if (code >= 95)
            return "storm"
        return "rain"
    }

    function request(url, onReady) {
        const call = new XMLHttpRequest()
        const host = url.split("/")[2]
        call.onreadystatechange = () => {
            if (call.readyState !== XMLHttpRequest.DONE)
                return
            if (call.status !== 200) {
                supervisor.fail(host + " answered with status " + call.status)
                return
            }
            try {
                onReady(JSON.parse(call.responseText))
            } catch (error) {
                supervisor.fail(host + " sent an unreadable answer: " + error)
            }
        }
        call.open("GET", url)
        call.send()
    }

    function locate(onPlaced) {
        if (place) {
            onPlaced(place)
            return
        }
        if (location.length > 0) {
            request("https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(location), answer => {
                const found = answer.results?.[0]
                if (!found) {
                    Log.warn("weather", "no place named " + location)
                    return
                }
                place = { latitude: found.latitude, longitude: found.longitude }
                onPlaced(place)
            })
            return
        }
        request("https://ipinfo.io/json", answer => {
            const parts = (answer.loc || "").split(",").map(Number)
            if (parts.length !== 2)
                return
            place = { latitude: parts[0], longitude: parts[1] }
            onPlaced(place)
        })
    }

    function readForecast(answer) {
        temperature = answer.current.temperature_2m
        kind = kindOf(answer.current.weather_code)
        rainChance = (answer.daily.precipitation_probability_max?.[0] ?? 0) / 100
        const found = []
        for (let day = 1; day <= forecastDays && day < answer.daily.weather_code.length; day++)
            found.push({ kind: kindOf(answer.daily.weather_code[day]), high: answer.daily.temperature_2m_max[day] })
        days = found
        fetchedAt = Date.now()
        isReady = true
        supervisor.succeed()
    }

    function refresh() {
        locate(spot => request("https://api.open-meteo.com/v1/forecast?timezone=auto&forecast_days=" + (forecastDays + 1)
            + "&latitude=" + spot.latitude + "&longitude=" + spot.longitude
            + "&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,precipitation_probability_max",
            weather.readForecast))
    }

    onLocationChanged: {
        place = null
        fetchedAt = 0
        if (isActive)
            refresh()
    }
    onIsActiveChanged: if (isActive && Date.now() - fetchedAt > Motion.dashboard.weatherPoll) refresh()

    Supervisor {
        id: supervisor
        name: "weather"
        isActive: weather.isActive
        onRestarted: weather.refresh()
    }

    Timer {
        interval: Motion.dashboard.weatherPoll
        running: weather.isActive
        repeat: true
        onTriggered: weather.refresh()
    }
}
