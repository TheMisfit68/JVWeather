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

/// Reports a number of convenient weatherconditions
/// Based on WeatherKit
public class WeatherReporter{
    
    let mininumPrecipitationLimit:Double
    let hotTemperatureLimit:Double
    let strongWindLimit:Double
    
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
    var needsUpdating:Bool{
        
        let now = Date()
        
        if let weatherDate = weather?.currentWeather.date{
            return ( now >= (weatherDate+updateInterval) )
        }else if let previousUpdate = self.previousUpdate {
            self.previousUpdate = now
            return ( now >= (previousUpdate+timeOutInterval) )
        }else{
            self.previousUpdate = now
            return true
        }
        
    }
    
    let weatherService = WeatherService()
    var weather:(currentWeather:CurrentWeather, DayWeather:Forecast<DayWeather>, HourWeather:Forecast<HourWeather>)?
    
    
    public init(daysInPast:Int = 2, daysInFuture:Int = 3, whitUpdateInterval updateInterval: TimeInterval = TimeInterval(3600)){
        
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

