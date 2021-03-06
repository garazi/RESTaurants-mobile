//
//  IXBaseShortCode.m
//  Ignite iOS Engine (IX)
//
//  Created by Robert Walsh on 10/7/13.
//  Copyright (c) 2013 Apigee, Inc. All rights reserved.
//

#import "IXBaseShortCode.h"
#import "IXProperty.h"
#import "IXEvalShortCode.h"
#import "IXGetShortCode.h"
#import "IXShortCodeFunction.h"
#import "NSString+IXAdditions.h"
#import "IXLogger.h"

// NSCoding Key Constants
static NSString* const kIXRawValueNSCodingKey = @"rawValue";
static NSString* const kIXObjectIDNSCodingKey = @"objectID";
#warning Suggest "method" and "function"
static NSString* const kIXMethodNameNSCodingKey = @"methodName";
static NSString* const kIXFunctionNameNSCodingKey = @"functionName";
static NSString* const kIXParametersNSCodingKey = @"parameters";
static NSString* const kIXRangeInPropertiesTextNSCodingKey = @"rangeInPropertiesText";

NSArray* ix_ValidRangesFromTextCheckingResult(NSTextCheckingResult* textCheckingResult)
{
    NSMutableArray* validRanges = [NSMutableArray array];
    NSUInteger numberOfRanges = [textCheckingResult numberOfRanges];
    for( int i = 0; i < numberOfRanges; i++)
    {
        NSRange range = [textCheckingResult rangeAtIndex:i];
        if( range.location != NSNotFound )
        {
            [validRanges addObject:[NSValue valueWithRange:range]];
        }
    }
    return validRanges;
}

@implementation IXBaseShortCode

-(instancetype)initWithRawValue:(NSString*)rawValue
                       objectID:(NSString*)objectID
                     methodName:(NSString*)methodName
                   functionName:(NSString*)functionName
                     parameters:(NSArray*)parameters
          rangeInPropertiesText:(NSRange)rangeInPropertiesText
{
    self = [super init];
    if( self )
    {
        _rawValue = [rawValue copy];
        _objectID = [objectID copy];
        _methodName = [methodName copy];
        _parameters = parameters;
        _rangeInPropertiesText = rangeInPropertiesText;
        
        [self setFunctionName:functionName];
    }
    return self;
}

-(instancetype)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithRawValue:[self rawValue]
                                                      objectID:[self objectID]
                                                    methodName:[self methodName]
                                                  functionName:[self functionName]
                                                    parameters:[[NSArray alloc] initWithArray:[self parameters] copyItems:YES]
                                         rangeInPropertiesText:[self rangeInPropertiesText]];
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[self rawValue] forKey:kIXRawValueNSCodingKey];
    [aCoder encodeObject:[self objectID] forKey:kIXObjectIDNSCodingKey];
    [aCoder encodeObject:[self methodName] forKey:kIXMethodNameNSCodingKey];
    [aCoder encodeObject:[self functionName] forKey:kIXFunctionNameNSCodingKey];
    [aCoder encodeObject:[self parameters] forKey:kIXParametersNSCodingKey];
    [aCoder encodeObject:[NSValue valueWithRange:[self rangeInPropertiesText]] forKey:kIXRangeInPropertiesTextNSCodingKey];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithRawValue:[aDecoder decodeObjectForKey:kIXRawValueNSCodingKey]
                         objectID:[aDecoder decodeObjectForKey:kIXObjectIDNSCodingKey]
                       methodName:[aDecoder decodeObjectForKey:kIXMethodNameNSCodingKey]
                     functionName:[aDecoder decodeObjectForKey:kIXFunctionNameNSCodingKey]
                       parameters:[aDecoder decodeObjectForKey:kIXParametersNSCodingKey]
            rangeInPropertiesText:[[aDecoder decodeObjectForKey:kIXRangeInPropertiesTextNSCodingKey] rangeValue]];
}

+(instancetype)shortCodeFromString:(NSString*)checkedString
                textCheckingResult:(NSTextCheckingResult*)textCheckingResult
{
    IXBaseShortCode* returnShortCode = nil;
    if( textCheckingResult )
    {
        NSArray* validRanges = ix_ValidRangesFromTextCheckingResult(textCheckingResult);
        
        NSUInteger validRangesCount = [validRanges count];
        if( validRangesCount >= 3 )
        {
            NSString* rawValue = [checkedString substringWithRange:[[validRanges firstObject] rangeValue]];
            NSString* objectIDWithMethodString = [checkedString substringWithRange:[[validRanges objectAtIndex:2] rangeValue]];
            
            if( [rawValue hasPrefix:kIX_EVAL_BRACKETS] )
            {
                IXProperty* evalPropertyValue = [[IXProperty alloc] initWithPropertyName:nil rawValue:objectIDWithMethodString];
                returnShortCode = [[IXEvalShortCode alloc] initWithRawValue:nil
                                                                   objectID:nil
                                                                 methodName:nil
                                                               functionName:nil
                                                                 parameters:@[evalPropertyValue]
                                                      rangeInPropertiesText:[textCheckingResult rangeAtIndex:0]];
            }
            else
            {
                NSString* objectID = nil;
                NSString* methodName = nil;
                NSString* functionName = nil;
                NSMutableArray* parameters = nil;
                
                NSMutableArray* objectIDWithMethodStringComponents = [NSMutableArray arrayWithArray:[objectIDWithMethodString componentsSeparatedByString:kIX_PERIOD_SEPERATOR]];
                objectID = [objectIDWithMethodStringComponents firstObject];
                
                [objectIDWithMethodStringComponents removeObject:objectID];
                if( [objectIDWithMethodStringComponents count] )
                {
                    methodName = [objectIDWithMethodStringComponents componentsJoinedByString:kIX_PERIOD_SEPERATOR];
                }
                
                if( validRangesCount >= 4 )
                {
                    functionName = [checkedString substringWithRange:[[validRanges objectAtIndex:3] rangeValue]];
                    if( validRangesCount >= 5 )
                    {
                        NSString* rawParameterString = [checkedString substringWithRange:[[validRanges objectAtIndex:4] rangeValue]];
                        NSArray* parameterStrings;
                        // Checks for pipe first, if no pipe, falls back to comma (need this for date formatting for example)
                        if ([rawParameterString containsSubstring:kIX_PIPE_SEPERATOR options:NO])
                        {
                            parameterStrings = [rawParameterString componentsSeparatedByString:kIX_PIPE_SEPERATOR];
                        }
                        else
                        {
                            parameterStrings = [rawParameterString componentsSeparatedByString:kIX_COMMA_SEPERATOR];
                        }
                        
                        for( NSString* parameter in parameterStrings )
                        {
                            IXProperty* parameterProperty = [[IXProperty alloc] initWithPropertyName:nil rawValue:parameter];
                            if( parameterProperty )
                            {
                                if( !parameters )
                                {
                                    parameters = [[NSMutableArray alloc] init];
                                }
                                [parameters addObject:parameterProperty];
                            }
                        }
                    }
                }
                
                Class shortCodeClass = NSClassFromString([NSString stringWithFormat:kIX_SHORTCODE_CLASS_NAME_FORMAT,[objectID capitalizedString]]);
                if( !shortCodeClass )
                {
                    // If the class doesn't exist this must be a Get shortcode.
                    shortCodeClass = [IXGetShortCode class];
                }
                else
                {
                    // If the class did exist then the objectID was really just the class of the shortcode in which case the objectID is not needed anymore.
                    objectID = nil;
                }
                
                if( [shortCodeClass isSubclassOfClass:[IXBaseShortCode class]] )
                {
                    returnShortCode = [[shortCodeClass alloc] initWithRawValue:rawValue
                                                                      objectID:objectID
                                                                    methodName:methodName
                                                                  functionName:functionName
                                                                    parameters:parameters
                                                         rangeInPropertiesText:[textCheckingResult rangeAtIndex:0]];
                }
            }
        }
    }
    return returnShortCode;
}

-(NSString*)evaluateAndApplyFunction
{
    NSString* returnValue = [self evaluate];
    IXBaseShortCodeFunction shortCodeFunction = [self shortCodeFunction];
    if( shortCodeFunction )
    {
        returnValue = shortCodeFunction(returnValue,[self parameters]);
    }
    return returnValue;
}

-(NSString*)evaluate
{
    return [self rawValue];
}

-(void)setFunctionName:(NSString *)functionName
{
    _functionName = [functionName copy];
    _shortCodeFunction = nil;
    if( [_functionName length] > 0 ) {
        
        _shortCodeFunction = [IXShortCodeFunction shortCodeFunctionWithName:_functionName];
        if( _shortCodeFunction == nil ) {
            IX_LOG_DEBUG(@"ERROR: Unknown short-code function with name: %@", _functionName);
        }
    }
}

@end
