//
//  WeatherReporter.swift
//  HAPiNest
//
//  Created by Jan Verrept on 26/09/2023.
//  Copyright © 2023 Jan Verrept. All rights reserved.
//
import Foundation
import WeatherKit
import JVLocation
import JVSwiftCore
import OSLog

/// Reports a number of convenient weatherconditions
/// Based on Apple's WeatherKit
public class WeatherReporter{
	let logger = Logger(subsystem: "be.oneclick.JVWeather", category: "WeatherReporter")

	/// Minimum precipitation limit in millimeters
	let mininumPrecipitationLimit:Double
	/// Hot temperature limit in degrees Celsius
    let hotTemperatureLimit:Double
	/// Strong wind limit in kilometers per hour
    let strongWindLimit:Double
    
	/// Manages the location to retrieve weather information
    var locationManager = LocationManager()
    
    let calendar = Calendar.current
    let daysInPast:Int
    let daysInFuture:Int
    let pastRange:Range<Int>
    let todayRange:ClosedRange<Int>
    let futureRange:ClosedRange<Int>
    let updateInterval:TimeInterval
    let timeOutInterval:TimeInterval
    var previousUpdate:Date? = nil
	
	/// Check whether weather data needs updating
    var needsUpdating:Bool{
        
        let now = Date()
        
		if let weatherDate = weather?.currentWeather.date, ( now >= (weatherDate+updateInterval) ){
			// Time to refresh the weather data
			self.previousUpdate = now
            return true
        }else if let previousUpdate = self.previousUpdate, ( now >= (previousUpdate+timeOutInterval) ) {
			// It took more than the timeout interval to retrieve the first weather data
            self.previousUpdate = now
            return true
        }else{
			// Retrieve the very first weather data
            self.previousUpdate = now
            return true
        }
        
    }
	/// Weather service instance for retrieving weather data from Apple's WeatherKit
    let weatherService = WeatherService()
	
	/// Tuple containing current, daily, and hourly weather data
    var weather:(currentWeather:CurrentWeather, DayWeather:Forecast<DayWeather>, HourWeather:Forecast<HourWeather>)?
    
	/// Initializes a new WeatherReporter instance
	/// - Parameters:
	///   - daysInPast: Number of past days to consider for weather forecast
	///   - daysInFuture: Number of future days to consider for weather forecast
	///   - updateInterval: Interval for updating weather data (in seconds)
    public init(daysInPast:Int = 3, daysInFuture:Int = 1, whitUpdateInterval updateInterval: TimeInterval = TimeInterval(3600)){
        
        self.mininumPrecipitationLimit = 10.0   // Unit for my current location = mm
        self.hotTemperatureLimit = 25.0         // Unit for my current location = °C
        self.strongWindLimit = 50.0            // Unit for my current location = km/h
        
        self.daysInPast = daysInPast
        self.daysInFuture = daysInFuture
        
        self.pastRange = 0..<daysInPast
        self.todayRange = daysInPast...daysInPast
        self.futureRange = daysInPast+1...daysInPast+daysInFuture
        
        self.updateInterval = updateInterval
        self.timeOutInterval = TimeInterval(10)
    }
    
	/// Indicates whether the weather was dry in the past
    public var wasDry:Bool{
        guard weather != nil else {return false}
        guard weather!.DayWeather.forecast.indices.contains(pastRange.lowerBound)
                && weather!.DayWeather.forecast.indices.contains(pastRange.upperBound) else {return false}
        return weather!.DayWeather.forecast[pastRange].allSatisfy({
            let lowPercipitationAmount = ($0.precipitationAmount.value <= mininumPrecipitationLimit)
            let highMaxTemperature = ($0.highTemperature.value >= hotTemperatureLimit)
            return lowPercipitationAmount && highMaxTemperature
        })
    }
    
	/// Indicates whether the weather is dry today
    public var isDry:Bool{
        guard weather != nil else {return false}
        guard weather!.DayWeather.forecast.indices.contains(todayRange.lowerBound)
                && weather!.DayWeather.forecast.indices.contains(todayRange.upperBound) else {return false}
        return weather!.DayWeather.forecast[todayRange].allSatisfy({
            let lowPercipitationAmount = ($0.precipitationAmount.value <= mininumPrecipitationLimit)
            let highMaxTemperature = ($0.highTemperature.value >= hotTemperatureLimit)
            return lowPercipitationAmount && highMaxTemperature
        })
        
    }
    
	/// Indicates whether the weather will be dry in the future
    public var willBeDry:Bool{
        guard weather != nil else {return false}
        guard weather!.DayWeather.forecast.indices.contains(futureRange.lowerBound)
                && weather!.DayWeather.forecast.indices.contains(futureRange.upperBound) else {return false}
        return weather!.DayWeather.forecast[futureRange].allSatisfy({
            let lowPercipitationAmount = ($0.precipitationAmount.value <= mininumPrecipitationLimit)
            let highMaxTemperature = ($0.highTemperature.value >= hotTemperatureLimit)
            return lowPercipitationAmount && highMaxTemperature
        })
    }
    
	/// Indicates whether the weather is windy
    public var isWindy:Bool{
        guard weather != nil else {return false}
        return (weather!.currentWeather.wind.speed.value >= strongWindLimit)
    }
    
    public func updateWeather()async{
        guard locationManager.location != nil else {locationManager.updateLocation(); return}
        if needsUpdating{
            
            let noonToday = Date().noon
            let startDate:Date = noonToday-(Double(daysInPast)*24*3600)
            let endDate:Date = noonToday+(Double(daysInFuture+1)*24*3600)
            
            weather = try? await weatherService.weather(for: locationManager.location!,
                                                        including: .current,
                                                        .daily(startDate: startDate, endDate: endDate),
                                                        .hourly(startDate: startDate, endDate: endDate)
														
														
            )
			
        }
		
    }
    
    
}

