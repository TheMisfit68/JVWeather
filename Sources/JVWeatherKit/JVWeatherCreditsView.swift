//
//  JVWeatherCreditsView.swift
//  
//
//  Created by Jan Verrept on 30/09/2023.
//

import Foundation
import SwiftUI
import WeatherKit
import OSLog

public extension WeatherService{
    
    struct CreditsView: View {
        
        public init(){} // An automaticly synthesized inititializer would get an access level of internal
        
        @Environment(\.colorScheme) var colorScheme: ColorScheme
        @State var attribution:WeatherAttribution?
        
        private var attributionLink: URL{
            guard attribution != nil else {return URL(string: "https://www.apple.com")!}
            return attribution!.legalPageURL
        }
        private var attributionLogo: URL?{
            guard attribution != nil else {return nil}
            return colorScheme == .light ? attribution?.combinedMarkLightURL : attribution?.combinedMarkDarkURL
        }
        
        public var body: some View {

            Link(destination: attributionLink) {
                AsyncImage(url: attributionLogo)
            }
            .task{
                do{
                    attribution = try await WeatherService.shared.attribution
                }catch{
                    let logger = Logger(subsystem: "be.oneclick.JVSwift", category: "WeatherCreditsView")
                    logger.error("\(error.localizedDescription)")
                }
            }
        }
    }
    
}


#Preview {
    WeatherService.CreditsView()
}
