//
//  main.swift
//  nstack-translations-generator
//
//  Created by Dominik Hadl on 15/10/2018.
//  Copyright © 2018 Nodes. All rights reserved.
//

import Foundation
import TranslationsGenerator

let json = "{\"data\":{\"en_EN\":{\"default\":{\"ok\":\"Ok\",\"cancel\":\"Cancel\",\"done\":\"Done\",\"restaurants\":\"Restaurants\",\"dishes\":\"Dishes\",\"minOrder\":\"Min. order\",\"min\":\"Min\",\"rating\":\"Rating\",\"email\":\"Email\",\"send\":\"Send\",\"name\":\"Name\",\"settings\":\"Settings\",\"noData\":\"No Data\",\"tryAgain\":\"Try Again\",\"yes\":\"Yes\",\"no\":\"No\",\"around\":\"Around\",\"defaultLanguageName\":\"English\",\"phone\":\"__phone\",\"save\":\"__save\",\"notRated\":\"Not Rated\",\"requests\":\"Requests\",\"required\":\"Required\",\"customize\":\"Customize\",\"notImplemented\":\"Not Implemented\",\"dotSeparator\":\"•\",\"loading\":\"Loading...\",\"continueButton\":\"Continue\",\"restaurant\":\"Restaurant\",\"restaurantCountSingular\":\"{restaurantCount} Restaurant\",\"restaurantCountPlural\":\"{restaurantCount} Restaurants\",\"free\":\"Free\"},\"login\":{\"loginButton\":\"Login!\",\"signInToContinue\":\"Sign in to continue\",\"signInText2\":\"We need a few details for you before we get your food to you.\",\"createAccount\":\"Create Account\",\"signIn\":\"Sign In\",\"signInBottomText1\":\"Alternatively, you can\",\"signInBottomText2\":\"checkout as a guest\"}}},\"meta\":{\"language\":{\"id\":56,\"name\":\"English\",\"locale\":\"en_EN\",\"direction\":\"LRM\",\"is_default\":false},\"is_cached\":false}}"
let data = json.data(using: .utf8)!
let settings = GeneratorSettings(plistPath: nil, keys: nil,
                                 outputPath: nil, flatTranslations: false, availableFromObjC: false)

print(try TranslationsGenerator.generateFromData(data, settings))

//try TranslationsGenerator.generate(CommandLine.arguments)
