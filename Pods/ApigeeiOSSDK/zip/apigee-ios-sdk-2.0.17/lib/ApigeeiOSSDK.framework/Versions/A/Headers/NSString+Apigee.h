/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

/*!
 @category NSString (Apigee)
 @discussion This category provides methods that capture network performance
 metrics on built-in NSString methods that perform network calls.
 */
@interface NSString (Apigee)

/*!
 @abstract Returns a string created by reading data from a given URL interpreted
    using a given encoding.
 @param url The URL to read.
 @param enc The encoding of the data at url.
 @param error If an error occurs, upon returns contains an NSError object that
    describes the problem. If you are not interested in possible errors, you may
    pass in NULL.
 @return A string created by reading data from URL using the encoding, enc. If
    the URL can’t be opened or there is an encoding error, returns nil.
 @discussion This method simply calls the NSString class method
    stringWithContentsOfURL:encoding:error: while capturing the network performance
    metrics for that call.
 */
+ (NSString*) stringWithTimedContentsOfURL:(NSURL *) url
                                  encoding:(NSStringEncoding) enc
                                     error:(NSError **) error;

/*!
 @abstract Returns a string created by reading data from a given URL and returns
    by reference the encoding used to interpret the data.
 @param url The URL from which to read data.
 @param enc Upon return, if url is read successfully, contains the encoding used
    to interpret the data.
 @param error If an error occurs, upon returns contains an NSError object that
    describes the problem. If you are not interested in possible errors, you may
    pass in NULL.
 @return A string created by reading data from url. If the URL can’t be opened
    or there is an encoding error, returns nil.
 @discussion This method simply calls the NSString class method
    stringWithContentsOfURL:usedEncoding:error: while capturing the network
    performance metrics for that call.
 */
+ (NSString*) stringWithTimedContentsOfURL:(NSURL *) url
                              usedEncoding:(NSStringEncoding *) enc
                                     error:(NSError **) error;

/*!
 @abstract Returns an NSString object initialized by reading data from a given
    URL interpreted using a given encoding.
 @param url The URL to read.
 @param enc The encoding of the file at url.
 @param error If an error occurs, upon returns contains an NSError object that
    describes the problem. If you are not interested in possible errors, pass
    in NULL.
 @return An NSString object initialized by reading data from url. If the URL
    can’t be opened or there is an encoding error, returns nil.
 @discussion This method simply calls the NSString instance method
    initWithContentsOfURL:encoding:error: while capturing the network
    performance metrics for that call.
 */
- (id) initWithTimedContentsOfURL:(NSURL *) url
                         encoding:(NSStringEncoding) enc
                            error:(NSError **) error;

/*!
 @abstract Returns an NSString object initialized by reading data from a given
    URL and returns by reference the encoding used to interpret the data.
 @param url The URL from which to read data.
 @param enc Upon return, if url is read successfully, contains the encoding
    used to interpret the data.
 @param error If an error occurs, upon returns contains an NSError object that
    describes the problem. If you are not interested in possible errors, pass
    in NULL.
 @return An NSString object initialized by reading data from url. If url can’t
    be opened or the encoding cannot be determined, returns nil.
 @discussion  This method simply calls the NSString instance method
    initWithContentsOfURL:usedEncoding:error: while capturing the network
    performance metrics for that call.
 */
- (id) initWithTimedContentsOfURL:(NSURL *) url
                     usedEncoding:(NSStringEncoding *) enc
                            error:(NSError **) error;

// convenience methods
/*!
 @internal
 */
- (BOOL) containsString:(NSString *)substringToLookFor;

@end
