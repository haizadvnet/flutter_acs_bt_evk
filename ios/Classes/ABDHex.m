/*
 * Copyright (C) 2014 Advanced Card Systems Ltd. All Rights Reserved.
 *
 * This software is the confidential and proprietary information of Advanced
 * Card Systems Ltd. ("Confidential Information").  You shall not disclose such
 * Confidential Information and shall use it only in accordance with the terms
 * of the license agreement you entered into with ACS.
 */

#import "ABDHex.h"

@implementation ABDHex

+ (NSString *)hexStringFromByteArray:(const uint8_t *)buffer length:(NSUInteger)length {

    NSString *hexString = @"";
    NSUInteger i = 0;

    for (i = 0; i < length; i++) {
        if (i == 0) {
            hexString = [hexString stringByAppendingFormat:@"%02X", buffer[i]];
        } else {
            hexString = [hexString stringByAppendingFormat:@" %02X", buffer[i]];
        }
    }

    return hexString;
}

+ (NSString *)hexStringFromByteArray:(NSData *)buffer {
    return [self hexStringFromByteArray:[buffer bytes] length:[buffer length]];
}

+ (NSData *)byteArrayFromHexString:(NSString *)hexString {

    NSData *byteArray = nil;
    uint8_t *buffer = NULL;
    NSUInteger i = 0;
    unichar c = 0;
    NSUInteger count = 0;
    int num = 0;
    BOOL first = YES;
    NSUInteger length = 0;

    // Count the number of HEX characters.
    for (i = 0; i < [hexString length]; i++) {

        c = [hexString characterAtIndex:i];
        if (((c >= '0') && (c <= '9')) ||
            ((c >= 'A') && (c <= 'F')) ||
            ((c >= 'a') && (c <= 'f'))) {
            count++;
        }
    }

    // Allocate the buffer.
    buffer = (uint8_t *) malloc((count + 1) / 2);
    if (buffer != NULL) {

        for (i = 0; i < [hexString length]; i++) {

            c = [hexString characterAtIndex:i];
            if ((c >= '0') && (c <= '9')) {
                num = c - '0';
            } else if ((c >= 'A') && (c <= 'F')) {
                num = c - 'A' + 10;
            } else if ((c >= 'a') && (c <= 'f')) {
                num = c - 'a' + 10;
            } else {
                num = -1;
            }

            if (num >= 0) {

                if (first) {

                    buffer[length] = num << 4;

                } else {

                    buffer[length] |= num;
                    length++;
                }

                first = !first;
            }
        }

        // Create the byte array.
        byteArray = [NSData dataWithBytesNoCopy:buffer length:length];
    }

    return byteArray;
}

//将NSString转换成十六进制的字符串则可使用如下方式:
+ (NSString *)convertStringToHexStr:(NSString *)str {
    if (!str || [str length] == 0) {
        return @"";
    }
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    return string;
}
// 十六进制转换为普通字符串
- (NSString *)stringFromHexString:(NSString *)hexString {
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:4];
    
    return unicodeString;
}
@end
