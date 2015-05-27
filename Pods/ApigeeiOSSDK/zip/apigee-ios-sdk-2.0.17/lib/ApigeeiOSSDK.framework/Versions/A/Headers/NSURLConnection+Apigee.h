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
 @category NSURLConnection (Apigee)
 @discussion This category provides methods that capture network performance
 metrics on built-in NSURLConnection methods that perform network calls.
 */

typedef void (^NSURLConnectionAsyncRequestCompletionHandler)(NSURLResponse* response, NSData* data, NSError* connectionError);

@interface NSURLConnection (Apigee)

/*!
 @abstract Creates and returns an initialized URL connection and begins to load
    the data for the URL request.
 @param request The URL request to load.
 @param delegate The delegate object for the connection.
 @return The URL connection for the URL request. Returns nil if a connection
    can't be created.
 @discussion This method simply calls the NSURLConnection class method
    connectionWithRequest:delegate: while capturing the network performance
    metrics for that call.
 */
+ (NSURLConnection*) timedConnectionWithRequest:(NSURLRequest *) request
                                       delegate:(id < NSURLConnectionDelegate >) delegate;

/*!
 @abstract Performs a synchronous load of the specified URL request.
 @param request The URL request to load.
 @param response Out parameter for the URL response returned by the server.
 @param error Out parameter used if an error occurs while processing the
    request. May be NULL.
 @return The downloaded data for the URL request. Returns nil if a connection
    could not be created or if the download fails.
 @discussion This method simply calls the NSURLConnection class method
    sendSynchronousRequest:returningResponse:error: while capturing the network
    performance metrics for that call.
 */
+ (NSData *) timedSendSynchronousRequest:(NSURLRequest *) request
                       returningResponse:(NSURLResponse **)response
                                   error:(NSError **)error;

/*!
 @abstract Loads the data for a URL request and executes a handler block on an
    operation queue when the request completes or fails.
 @param request The URL request to load.
 @param queue The operation queue to which the handler block is dispatched when
    the request completes or failed.
 @param handler The handler block to execute.
 @discussion This method simply calls the NSURLConnection class method
    sendAsynchronousRequest:queue:completionHandler: while capturing the network
    performance metrics for that call.
 */
+ (void) timedSendAsynchronousRequest:(NSURLRequest *)request
                                queue:(NSOperationQueue *)queue
                    completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;

/*!
 @abstract Returns an initialized URL connection and begins to load the data
    for the URL request.
 @param request The URL request to load.
 @param delegate The delegate object for the connection.
 @return The URL connection for the URL request. Returns nil if a connection
    can't be initialized.
 @discussion This method simply calls the NSURLConnection instance method
    initWithRequest:delegate: while capturing the network performance metrics
    for that call.
 */
- (id) initTimedConnectionWithRequest:(NSURLRequest *)request
                             delegate:(id < NSURLConnectionDelegate >)delegate;

/*!
 @abstract Returns an initialized URL connection and begins to load the data
    for the URL request, if specified.
 @param request The URL request to load.
 @param delegate The delegate object for the connection.
 @param startImmediately YES if the connection should being loading data
    immediately, otherwise NO.
 @return The URL connection for the URL request. Returns nil if a connection
    can't be initialized.
 @discussion This method simply calls the NSURLConnection instance method
    initWithRequest:delegate:startImmediately: while capturing the network
    performance metrics for that call.
 */
- (id) initTimedConnectionWithRequest:(NSURLRequest *)request
                             delegate:(id < NSURLConnectionDelegate >) delegate
                     startImmediately:(BOOL) startImmediately;


// ******  swizzling  *******

+ (BOOL)apigeeSwizzlingSetup;


@end
