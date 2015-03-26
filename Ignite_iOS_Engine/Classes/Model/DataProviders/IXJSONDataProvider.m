//
//  IXJSONDataProvider.m
//  Ignite_iOS_Engine
//
//  Created by Robert Walsh on 12/6/13.
//  Copyright (c) 2013 Ignite. All rights reserved.
//

#import "IXJSONDataProvider.h"

#import "AFHTTPClient.h"
#import "AFOAuth2Client.h"

#import "IXAFJSONRequestOperation.h"
#import "IXAppManager.h"
#import "IXDataGrabber.h"
#import "IXLogger.h"
#import "IXViewController.h"
#import "IXSandbox.h"

// TODO: Clean up naming and document
IX_STATIC_CONST_STRING kIXModifyResponse = @"modify_response";
IX_STATIC_CONST_STRING kIXModifyType = @"modify.type";
IX_STATIC_CONST_STRING kIXDelete = @"delete";
IX_STATIC_CONST_STRING kIXAppend = @"append";

IX_STATIC_CONST_STRING kIXTopLevelContainer = @"top_level_container";

IX_STATIC_CONST_STRING kIXPredicateFormat = @"predicate.format";            //e.g. "%K CONTAINS[c] %@"
IX_STATIC_CONST_STRING kIXPredicateArguments = @"predicate.arguments";      //e.g. "email,[[inputbox.text]]"

IX_STATIC_CONST_STRING kIXJSONToAppend = @"json_to_append";
IX_STATIC_CONST_STRING kIXParseJSONAsObject = @"parse_json_as_object";

// TODO: These should be migrated to base data provider
IX_STATIC_CONST_STRING kIXResponseHeadersPrefix = @"response.headers.";
IX_STATIC_CONST_STRING kIXResponseTime = @"response.time";

@interface IXJSONDataProvider ()

@property (nonatomic,strong) id lastResponseHeaders;
@property (nonatomic) CGFloat responseTime;

@end

@implementation IXJSONDataProvider

-(instancetype)init
{
    self = [super init];
    if ( self ) {
        _rowDataResultsDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)applySettings
{
    [super applySettings];
 
    if( [self acceptedContentType] )
    {
        [IXAFJSONRequestOperation addAcceptedContentType:[self acceptedContentType]];
    }
}

-(void)fireLoadFinishedEventsFromCachedResponse
{
    NSString* rawResponseString = [self responseRawString];
    NSData* rawResponseData = [rawResponseString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* __autoreleasing error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:rawResponseData options:0 error:&error];
    if( jsonObject )
    {
        [self setLastJSONResponse:jsonObject];
        [super fireLoadFinishedEventsFromCachedResponse];
    }
    
    if ([self responseHeaders])
    {
        [self setLastResponseHeaders:[self responseHeaders]];
    }
}

-(void)loadData:(BOOL)forceGet
{
    [super loadData:forceGet];
    
    if (forceGet == NO)
    {
        [self fireLoadFinishedEvents:YES shouldCacheResponse:NO];
    }
    else
    {
        [self setLastJSONResponse:nil];
        [self setLastResponseHeaders:nil];
        [self setResponseRawString:nil];
        [self setResponseStatusCode:0];
        [self setResponseErrorMessage:nil];
        
        if ( [self dataBaseURL] != nil )
        {
            if( ![self isPathLocal] )
            {
        
                __block CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
                
                __weak typeof(self) weakSelf = self;
                IXAFJSONRequestOperation* jsonRequestOperation = [[IXAFJSONRequestOperation alloc] initWithRequest:[self createURLRequest]];
                [jsonRequestOperation setJSONReadingOptions:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves];
                [jsonRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    CFTimeInterval elapsedTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
                    [weakSelf setResponseTime:elapsedTime];
                    
                    [weakSelf setResponseStatusCode:[[operation response] statusCode]];
                    [weakSelf setLastResponseHeaders:[[operation response] allHeaderFields]];
                    
                    if( [NSJSONSerialization isValidJSONObject:responseObject] )
                    {
                        [weakSelf setResponseRawString:[operation responseString]];
                        [weakSelf setLastJSONResponse:responseObject];
                        [weakSelf fireLoadFinishedEvents:YES shouldCacheResponse:YES];
                    }
                    else
                    {
                        [weakSelf setResponseErrorMessage:[[operation error] description]];
                        [weakSelf fireLoadFinishedEvents:NO shouldCacheResponse:NO];
                    }
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    
                    
                    CFTimeInterval elapsedTime = CFAbsoluteTimeGetCurrent() - startTime;
                    [weakSelf setResponseTime:elapsedTime];

                    [weakSelf setLastResponseHeaders:[[operation response] allHeaderFields]];
                    [weakSelf setResponseStatusCode:[[operation response] statusCode]];
                    [weakSelf setResponseErrorMessage:[error description]];
                    [weakSelf setResponseRawString:[operation responseString]];

                    id responseJSONObject = [(IXAFJSONRequestOperation*)operation responseJSON];
                    if( [NSJSONSerialization isValidJSONObject:responseJSONObject] )
                    {
                        [weakSelf setLastJSONResponse:responseJSONObject];
                    }

                    [weakSelf fireLoadFinishedEvents:NO shouldCacheResponse:NO];
                }];
                
                
                [[self httpClient] enqueueHTTPRequestOperation:jsonRequestOperation];
            }
            else
            {
                __weak typeof(self) weakSelf = self;
                [[IXDataGrabber sharedDataGrabber] grabJSONFromPath:[self fullDataLocation]
                                                             asynch:YES
                                                        shouldCache:NO
                                                    completionBlock:^(id jsonObject, NSString* stringValue, NSError *error) {
                                                        
                                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{                                                            
                                                            
                                                            if( [NSJSONSerialization isValidJSONObject:jsonObject] )
                                                            {
                                                                [weakSelf setResponseRawString:stringValue];
                                                                [weakSelf setLastJSONResponse:jsonObject];
                                                                IX_dispatch_main_sync_safe(^{
                                                                    [weakSelf fireLoadFinishedEvents:YES shouldCacheResponse:YES];
                                                                });
                                                            }
                                                            else
                                                            {
                                                                [weakSelf setResponseErrorMessage:[error description]];
                                                                IX_dispatch_main_sync_safe(^{
                                                                    [weakSelf fireLoadFinishedEvents:NO shouldCacheResponse:NO];
                                                                });
                                                            }
                                                        });
                }];
            }
        }
        else
        {
            IX_LOG_ERROR(@"ERROR: 'data.baseurl' of control [%@] is %@; is 'data.baseurl' defined correctly in your data_provider?", self.ID, self.dataBaseURL);
        }
    }
}

-(void)calculateAndStoreDataRowResultsForDataRowPath:(NSString*)dataRowPath
{
    NSObject* jsonObject = nil;
    if( [dataRowPath length] <= 0 && [[self lastJSONResponse] isKindOfClass:[NSArray class]] )
    {
        jsonObject = [self lastJSONResponse];
    }
    else
    {
        jsonObject = [self objectForPath:dataRowPath container:[self lastJSONResponse]];
    }

    NSArray* rowDataResults = nil;
    if( [jsonObject isKindOfClass:[NSArray class]] )
    {
        rowDataResults = (NSArray*)jsonObject;
    }
    if( rowDataResults )
    {
        NSPredicate* predicate = [self predicate];
        if( predicate )
        {
            rowDataResults = [rowDataResults filteredArrayUsingPredicate:predicate];
        }
        NSSortDescriptor* sortDescriptor = [self sortDescriptor];
        if( sortDescriptor )
        {
            rowDataResults = [rowDataResults sortedArrayUsingDescriptors:@[sortDescriptor]];
        }
    }

    if( [dataRowPath length] && rowDataResults != nil )
    {
        [[self rowDataResultsDict] setObject:rowDataResults forKey:dataRowPath];
    }
}

-(void)fireLoadFinishedEvents:(BOOL)loadDidSucceed shouldCacheResponse:(BOOL)shouldCacheResponse
{
    if( loadDidSucceed )
    {
        NSString* dataRowBasePath = [self dataRowBasePath];
        [self calculateAndStoreDataRowResultsForDataRowPath:dataRowBasePath];

        for( NSString* dataRowKey in [[self rowDataResultsDict] allKeys] )
        {
            if( ![dataRowKey isEqualToString:dataRowBasePath] )
            {
                [self calculateAndStoreDataRowResultsForDataRowPath:dataRowKey];
            }
        }
    }
    [super fireLoadFinishedEvents:loadDidSucceed shouldCacheResponse:shouldCacheResponse];
}

-(void)applyFunction:(NSString *)functionName withParameters:(IXPropertyContainer *)parameterContainer
{
    BOOL needsToRecacheResponse = NO;
    if( [functionName isEqualToString:kIXModifyResponse] )
    {
        NSString* modifyResponseType = [parameterContainer getStringPropertyValue:kIXModifyType defaultValue:nil];
        if( [modifyResponseType length] > 0 )
        {
            NSString* topLevelContainerPath = [parameterContainer getStringPropertyValue:kIXTopLevelContainer defaultValue:nil];
            id topLevelContainer = [self objectForPath:topLevelContainerPath container:[self lastJSONResponse]];

            if( [topLevelContainer isKindOfClass:[NSMutableArray class]] )
            {
                NSMutableArray* topLevelArray = (NSMutableArray*) topLevelContainer;

                if( [modifyResponseType isEqualToString:kIXDelete] )
                {
                    NSString* predicateFormat = [parameterContainer getStringPropertyValue:kIXPredicateFormat defaultValue:nil];
                    NSArray* predicateArgumentsArray = [parameterContainer getCommaSeperatedArrayListValue:kIXPredicateArguments defaultValue:nil];

                    if( [predicateFormat length] > 0 && [predicateArgumentsArray count] > 0 )
                    {
                        NSPredicate* predicate = [NSPredicate predicateWithFormat:predicateFormat argumentArray:predicateArgumentsArray];
                        if( predicate != nil )
                        {
                            NSArray* filteredArray = [topLevelContainer filteredArrayUsingPredicate:predicate];
                            [topLevelArray removeObjectsInArray:filteredArray];
                            needsToRecacheResponse = YES;
                        }
                    }
                }
                else if( [modifyResponseType isEqualToString:kIXAppend] )
                {
                    id jsonToAppendObject = nil;
                    if( [parameterContainer getBoolPropertyValue:kIXParseJSONAsObject defaultValue:NO] )
                    {
                        jsonToAppendObject = [[parameterContainer getAllPropertiesObjectValues:NO] objectForKey:kIXJSONToAppend];
                    }
                    else
                    {
                        NSString* jsonToAppendString = [parameterContainer getStringPropertyValue:kIXJSONToAppend defaultValue:nil];
                        jsonToAppendObject = [NSJSONSerialization JSONObjectWithData:[jsonToAppendString dataUsingEncoding:NSUTF8StringEncoding]
                                                                                options:NSJSONReadingMutableContainers|NSJSONReadingAllowFragments
                                                                                    error:nil];
                    }


                    if( jsonToAppendObject != nil )
                    {
                        [topLevelArray addObject:jsonToAppendObject];
                        needsToRecacheResponse = YES;
                    }
                }

                if( needsToRecacheResponse )
                {
                    NSError* error;
                    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[self lastJSONResponse]
                                                                       options:0
                                                                         error:&error];
                    if( [jsonData length] > 0 && error == nil )
                    {
                        [self setResponseRawString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
                        [self cacheResponse];
                    }
                }
            }

        }
    }
    else
    {
        [super applyFunction:functionName withParameters:parameterContainer];
    }
}

-(void)cacheResponse
{
    if( [self lastJSONResponse] != nil )
    {
        NSError* error;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[self lastJSONResponse]
                                                           options:0
                                                             error:&error];
        if( [jsonData length] > 0 && error == nil )
        {
            [self setResponseRawString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
        }
    }
    
    if ( [self lastResponseHeaders] != nil )
    {
        [self setResponseHeaders:[self lastResponseHeaders]];
    }
    
    [super cacheResponse];
}

-(NSString*)getReadOnlyPropertyValue:(NSString *)propertyName
{
    NSString* returnValue = [super getReadOnlyPropertyValue:propertyName];
    if( returnValue == nil )
    {
        if ([propertyName hasPrefix:kIXResponseHeadersPrefix]) {
            NSString* headerKey = [[propertyName componentsSeparatedByString:kIX_PERIOD_SEPERATOR] lastObject];
            @try {
                returnValue = [self lastResponseHeaders][headerKey];
                if (!returnValue) {
                    returnValue = [self lastResponseHeaders][[headerKey lowercaseString]]; // try again with lowercase?
                }
            }
            @catch (NSException *exception) {
                DDLogDebug(@"No header value named '%@' exists in response object", headerKey);
            }
        }
        else if ([propertyName hasPrefix:kIXResponseTime]) {
            returnValue = [NSString stringWithFormat: @"%0.f", [self responseTime]];
        }
        else if( ![[self propertyContainer] propertyExistsForPropertyNamed:propertyName] )
        {
            NSObject* jsonObject = [self objectForPath:propertyName container:[self lastJSONResponse]];
            if( jsonObject )
            {
                if( [jsonObject isKindOfClass:[NSString class]] )
                {
                    returnValue = (NSString*)jsonObject;
                }
                else if( [jsonObject isKindOfClass:[NSNumber class]] )
                {
                    returnValue = [(NSNumber*)jsonObject stringValue];
                }
                else if( [NSJSONSerialization isValidJSONObject:jsonObject] )
                {
                    NSError* __autoreleasing jsonConvertError = nil;
                    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:&jsonConvertError];
                    if( jsonConvertError == nil && jsonData )
                    {
                        returnValue = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                }
            }
        }
    }
    return returnValue;
}

-(NSString*)rowDataRawStringResponse
{
    NSString* returnValue = nil;
    NSArray* results = [self rowDataResultsDict][[self dataRowBasePath]];
    if( [results count] > 0 )
    {
        NSError *error;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:results
                                                           options:0
                                                             error:&error];
        if( [jsonData length] > 0 && error == nil )
        {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            returnValue = jsonString;
        }
    }
    return returnValue;
}

-(NSString*)rowDataForIndexPath:(NSIndexPath*)rowIndexPath keyPath:(NSString*)keyPath dataRowBasePath:(NSString*)dataRowBasePath
{
    if( [dataRowBasePath length] <= 0 )
    {
        dataRowBasePath = [self dataRowBasePath];
    }

    NSString* returnValue = [super rowDataForIndexPath:rowIndexPath keyPath:keyPath dataRowBasePath:dataRowBasePath];
    if( keyPath && rowIndexPath )
    {
        NSArray* dataRowContainer = [self rowDataResultsDict][dataRowBasePath];

        if( dataRowContainer != nil )
        {
            NSString* jsonKeyPath = [NSString stringWithFormat:@"%li.%@",(long)rowIndexPath.row,keyPath];
            returnValue = [self stringForPath:jsonKeyPath container:dataRowContainer];
        }
    }
    return returnValue;
}

-(NSUInteger)rowCount:(NSString *)dataRowBasePath
{
    if( [dataRowBasePath length] <= 0 )
    {
        dataRowBasePath = [self dataRowBasePath];
    }

    if( [self rowDataResultsDict][dataRowBasePath] == nil )
    {
        [self calculateAndStoreDataRowResultsForDataRowPath:dataRowBasePath];
    }

    return [[self rowDataResultsDict][dataRowBasePath] count];
}

-(NSString*)stringForPath:(NSString*)jsonXPath container:(NSObject*)container
{
    NSString* returnValue = nil;
    NSObject* jsonObject = [self objectForPath:jsonXPath container:container];
    if( jsonObject )
    {
        if( [jsonObject isKindOfClass:[NSString class]] ) {
            returnValue = (NSString*)jsonObject;
        } else if( [jsonObject isKindOfClass:[NSNumber class]] ) {
            returnValue = [((NSNumber*)jsonObject) stringValue];
        } else if( [jsonObject isKindOfClass:[NSNull class]] ) {
            returnValue = nil;
        } else if( [NSJSONSerialization isValidJSONObject:jsonObject] ) {
            
            NSError* __autoreleasing jsonConvertError = nil;
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:&jsonConvertError];
            
            if( jsonConvertError == nil && jsonData ) {
                returnValue = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            } else {
                IX_LOG_WARN(@"WARNING from %@ in %@ : Error Converting JSON object : %@",THIS_FILE,THIS_METHOD,[jsonConvertError description]);
            }
        } else {
            IX_LOG_WARN(@"WARNING from %@ in %@ : Invalid JSON Object : %@",THIS_FILE,THIS_METHOD,[jsonObject description]);
        }
    }
    return returnValue;
}

-(NSString*)getQueryValueOutOfValue:(NSString*)value
{
    NSString* returnValue = value;
    NSArray* seperatedValue = [value componentsSeparatedByString:@"?"];
    if( [seperatedValue count] > 0 )
    {
        NSString* objectID = [seperatedValue firstObject];
        NSString* propertyName = [seperatedValue lastObject];
        if( [objectID isEqualToString:kIXSessionRef] )
        {
            returnValue = [[[IXAppManager sharedAppManager] sessionProperties] getStringPropertyValue:propertyName defaultValue:value];
        }
        else if( [objectID isEqualToString:kIXAppRef] )
        {
            returnValue = [[[IXAppManager sharedAppManager] appProperties] getStringPropertyValue:propertyName defaultValue:value];
        }
        else if( [objectID isEqualToString:kIXViewControlRef] )
        {
            returnValue = [[[self sandbox] viewController] getViewPropertyNamed:propertyName];
            if( returnValue == nil )
            {
                returnValue = value;
            }
        }
        else
        {
            NSArray* objectWithIDArray = [[self sandbox] getAllControlsAndDataProvidersWithID:objectID withSelfObject:self];
            IXBaseObject* baseObject = [objectWithIDArray firstObject];

            if( baseObject )
            {
                returnValue = [baseObject getReadOnlyPropertyValue:propertyName];
                if( returnValue == nil )
                {
                    returnValue = [[baseObject propertyContainer] getStringPropertyValue:propertyName defaultValue:value];
                }
            }
        }
    }
    return returnValue;
}

- (NSObject*)objectForPath:(NSString *)jsonXPath container:(NSObject*) currentNode
{
    if (currentNode == nil) {
        return nil;
    }
    
    if(![currentNode isKindOfClass:[NSDictionary class]] && ![currentNode isKindOfClass:[NSArray class]]) {
        return currentNode;
    }
    if ([jsonXPath hasPrefix:kIX_PERIOD_SEPERATOR]) {
        jsonXPath = [jsonXPath substringFromIndex:1];
    }
    
    NSString *currentKey = [[jsonXPath componentsSeparatedByString:kIX_PERIOD_SEPERATOR] firstObject];
    NSObject *nextNode;
    // if dict -> get value
    if ([currentNode isKindOfClass:[NSDictionary class]]) {
        NSDictionary *currentDict = (NSDictionary *) currentNode;
        nextNode = currentDict[jsonXPath];
        if( nextNode != nil )
        {
            return nextNode;
        }
        else
        {
            nextNode = currentDict[currentKey];
        }
    }
    
    if ([currentNode isKindOfClass:[NSArray class]]) {
        NSArray * currentArray = (NSArray *) currentNode;
        @try {
            if( [currentKey containsString:@"="] ) // current key is actually looking to filter array if theres an '=' character
            {
                NSArray* currentKeySeperated = [currentKey componentsSeparatedByString:@"="];
                if( [currentKeySeperated count] > 1 ) {
                    NSString* currentKeyValue = [currentKeySeperated lastObject];
                    if( [currentKeyValue rangeOfString:@"?"].location != NSNotFound )
                    {
                        currentKeyValue = [self getQueryValueOutOfValue:currentKeyValue];
                    }
                    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(%K == %@)",[currentKeySeperated firstObject],currentKeyValue];
                    NSArray* filteredArray = [currentArray filteredArrayUsingPredicate:predicate];
                    if( [filteredArray count] >= 1 ) {
                        if( [filteredArray count] == 1 ) {
                            nextNode = [filteredArray firstObject];
                        } else {
                            nextNode = filteredArray;
                        }
                    }
                }
            }
            else // current key must be an number
            {
                if( [currentKey isEqualToString:@"$count"] || [currentKey isEqualToString:@".$count"] )
                {
                    return [NSString stringWithFormat:@"%lu",(unsigned long)[currentArray count]];
                }
                else if ([currentArray count] > 0)
                {
                    nextNode = [currentArray objectAtIndex:[currentKey integerValue]];
                }
                else
                {
                    @throw [NSException exceptionWithName:@"NSRangeException"
                                                   reason:@"Specified array index is out of bounds"
                                                 userInfo:nil];
                }
            }
        }
        @catch (NSException *exception) {
            IX_LOG_ERROR(@"ERROR : %@ Exception in %@ : %@; attempted to retrieve index %@ from %@",THIS_FILE,THIS_METHOD,exception,currentKey, jsonXPath);
        }
    }
    
    NSString * nextXPath = [jsonXPath stringByReplacingCharactersInRange:NSMakeRange(0, [currentKey length]) withString:kIX_EMPTY_STRING];
    if( nextXPath.length <= 0 )
    {
        return nextNode;
    }
    // call recursively with the new xpath and the new Node
    return [self objectForPath:nextXPath container: nextNode];
}

@end
