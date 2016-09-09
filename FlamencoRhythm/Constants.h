//
//  Constants.h
//  FlamencoRhythm
//
//  Created by Nirma on 09/03/16.
//  Copyright © 2016 Intelliswift Software Pvt. Ltd. All rights reserved.
//

#ifndef Constants_h
#define Constants_h



#define HELVETICA_BOLD @"HelveticaNeue-Bold"
#define HELVETICA_LIGHT @"HelveticaNeue-Light"
#define HELVETICA_REGULAR @"HelveticaNeue"
#define SANFRANSISCO_BOLD @".HelveticaNeueDeskInterface-Bold"
#define SANFRANSISCO_REGULAR @"SFUIText-Regular"
#define SANFRANSISCO_LIGHT @"SFUIText-Light"
#define SANFRANSISCO_MEDIUM @"SFUIText-Medium"
#define SANFRANSISCO_ULTRALIGHT @"SFUIDisplay-Ultralight"

#define FONT_REGULAR SANFRANSISCO_REGULAR
#define FONT_BOLD SANFRANSISCO_BOLD
#define FONT_LIGHT SANFRANSISCO_LIGHT
#define FONT_MEDIUM SANFRANSISCO_MEDIUM
#define FONT_ULTRALIGHT SANFRANSISCO_ULTRALIGHT

#define FONT_NAME @"Gill Sans"

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]

#ifndef DLog
#   ifdef DEBUG
#       define DLog(...) NSLog(__VA_ARGS__)
#   else
#       define DLog( ...)
#   endif // NDEBUG
#endif // DLog


// In App Purchase
#define IN_APP_PURCHASE_ENABLE 0

#define PRODUCT_ID @"com.febe.musicmemos"

#define PRODUCT_PURCHASED @"PURCHASED"
#define PRODUCT_NOT_PURCHASED @"NOT PURCHASED"

#define SAMPLE_RATE 44100

// For selected input mic.
enum UserInputMic { kUserInput_BuiltIn, kUserInput_Headphone };

/********************************colors***************************/
 #define FONT_BLUE_COLOR 0x0070ff //0x007aff //0x0079ff  //2,122,255
#define FONT_COLOR [UIColor colorWithRed:0/225.0 green:122/255.0 blue:255.0/255.0 alpha:1]
#define NAVIGATION_COLOR  0xefeff4//0xeeeef4
#define GRAY_COLOR 0xceced2 
#define FONT_GRAY_COLOR 0x8e8e92
#define DELETE_BUTTON_COLOR 0xfb4438
#define SHARE_BUTTON_COLOR 0xceced2
#define LIGHT_GRAY_COLOR [UIColor colorWithRed:236.0/255.0 green:236.0/255.0 blue:236.0/255.0 alpha:1]
#endif /* Constants_h */
