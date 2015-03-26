//
//  IXControlCacheContainer.m
//  Ignite_iOS_Engine
//
//  Created by Robert Walsh on 3/17/14.
//  Copyright (c) 2014 Ignite. All rights reserved.
//

#import "IXControlCacheContainer.h"

#import "IXDataGrabber.h"
#import "IXPropertyContainer.h"
#import "IXActionContainer.h"
#import "IXBaseControl.h"
#import "IXCustom.h"
#import "IXLogger.h"
#import "IXBaseDataProviderConfig.h"
#import "IXBaseControlConfig.h"

static NSCache* sControlCacheContainerCache;
IX_STATIC_CONST_STRING kIXControlCacheContainerCacheName = @"com.ignite.ControlCacheContainerCache";

@implementation IXControlCacheContainer

+(void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sControlCacheContainerCache = [[NSCache alloc] init];
        [sControlCacheContainerCache setName:kIXControlCacheContainerCacheName];
    });
}

+(void)clearCache
{
    [sControlCacheContainerCache removeAllObjects];
}

-(instancetype)initWithControlType:(NSString*)controlType
                        styleClass:(NSString*)styleClass
                 propertyContainer:(IXPropertyContainer*)propertyContainer
                   actionContainer:(IXActionContainer*)actionContainer
               childConfigControls:(NSArray*)childConfigControls
               dataProviderConfigs:(NSArray*)dataProviderConfigs;
{
    self = [super init];
    if( self )
    {
        _controlType = [controlType copy];
        _styleClass = [styleClass copy];
        _propertyContainer = propertyContainer;
        _actionContainer = actionContainer;
        _childConfigControls = childConfigControls;
        _dataProviderConfigs = dataProviderConfigs;
    }
    return self;
}

-(instancetype)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithControlType:[self controlType]
                                                       styleClass:[self styleClass]
                                                propertyContainer:[[self propertyContainer] copy]
                                                  actionContainer:[[self actionContainer] copy]
                                              childConfigControls:[[NSArray alloc] initWithArray:[self childConfigControls] copyItems:YES]
                                              dataProviderConfigs:[[NSArray alloc] initWithArray:[self dataProviderConfigs] copyItems:YES]];
}

-(Class)controlClass
{
    Class controlClass = nil;
    NSString* controlType = [self controlType];
    if( [controlType length] ) {
        controlClass = NSClassFromString([NSString stringWithFormat:kIX_CONTROL_CLASS_NAME_FORMAT,controlType]);
    } else {
        controlClass = [IXLayout class];
    }
    return controlClass;
}

+(void)populateControlsCustomControlChildren:(IXBaseControl*)control
{
    for( IXBaseControl* childControl in [control childObjects] )
    {
        if( [childControl isKindOfClass:[IXCustom class]] )
        {
            IXCustom* customControl = (IXCustom*)childControl;
            NSString* pathToJSON = [[customControl propertyContainer] getPathPropertyValue:@"control_location" basePath:nil defaultValue:nil];
            if( pathToJSON == nil )
            {
                IX_LOG_WARN(@"WARNING from %@ in %@ : Path to custom control is nil!!! \n Custom Control Description : %@",THIS_FILE,THIS_METHOD,[customControl description]);
                [[customControl actionContainer] executeActionsForEventNamed:@"load_failed"];
            }
            else
            {
                [customControl setPathToJSON:pathToJSON];
                BOOL loadAsync = [[customControl propertyContainer] getBoolPropertyValue:@"load_async" defaultValue:YES] && ![sControlCacheContainerCache objectForKey:pathToJSON];
                [IXControlCacheContainer populateControl:customControl
                                          withJSONAtPath:pathToJSON
                                               loadAsync:loadAsync
                                         completionBlock:^(BOOL didSucceed, IXBaseControl* populatedControl, NSError *error) {
                                              if( didSucceed )
                                              {
                                                  if( loadAsync )
                                                  {
                                                      if( [populatedControl isKindOfClass:[IXCustom class]] )
                                                      {
                                                          [((IXCustom*)populatedControl) setFirstLoad:YES];
                                                      }
                                                      [populatedControl applySettings];
                                                      [populatedControl layoutControl];
                                                  }
                                                  [[populatedControl actionContainer] executeActionsForEventNamed:@"did_load"];
                                              }
                                              else
                                              {
                                                  [[populatedControl actionContainer] executeActionsForEventNamed:@"load_failed"];
                                              }
                                         }];
            }
        }
        
        [IXControlCacheContainer populateControlsCustomControlChildren:childControl];
    }
}

+(void)populateControl:(IXBaseControl *)control controlCacheContainer:(IXControlCacheContainer*)controlCacheContainer completionBlock:(IXPopulateControlCompletionBlock)completionBlock
{
    if( control && controlCacheContainer != nil )
    {
        if( [control styleClass] == nil )
        {
            [control setStyleClass:[controlCacheContainer styleClass]];
        }
        
        IXPropertyContainer* controlPropertyContainer = [control propertyContainer];
        if( [controlCacheContainer propertyContainer] )
        {
            [control setPropertyContainer:[[controlCacheContainer propertyContainer] copy]];
            [[control propertyContainer] addPropertiesFromPropertyContainer:controlPropertyContainer evaluateBeforeAdding:NO replaceOtherPropertiesWithTheSameName:YES];
        }
        if( [control actionContainer] )
        {
            [[control actionContainer] addActionsFromActionContainer:[[controlCacheContainer actionContainer] copy]];
        }
        else
        {
            [control setActionContainer:[[controlCacheContainer actionContainer] copy]];
        }
        
        NSMutableArray* dataProviders = [[NSMutableArray alloc] init];
        for( IXBaseDataProviderConfig* dataProviderConfig in [controlCacheContainer dataProviderConfigs] )
        {
            IXBaseDataProvider* dataProvider = [dataProviderConfig createDataProvider];
            if( dataProvider )
            {
                [dataProviders addObject:dataProvider];
            }
        }
        
        if( [control isKindOfClass:[IXCustom class]] )
        {
            [((IXCustom*)control) setDataProviders:dataProviders];
        }
        else
        {
            [[control sandbox] addDataProviders:dataProviders];
        }
        
        for( IXBaseControlConfig* controlConfig in [controlCacheContainer childConfigControls] )
        {
            IXBaseControl* childControl = [controlConfig createControl];
            if( childControl )
            {
                [control addChildObject:childControl];
            }
        }
        
        [IXControlCacheContainer populateControlsCustomControlChildren:control];
        
        completionBlock(YES,control,nil);
    }
    else
    {
        completionBlock(NO,control,[NSError errorWithDomain:@"No control cache found." code:0 userInfo:nil] );
    }
}

+(void)createControlWithControlCacheContainer:(IXControlCacheContainer*)controlCacheContainer
                              completionBlock:(IXCreateControlCompletionBlock)completionBlock
{
    if( controlCacheContainer != nil )
    {
        Class controlClass = [controlCacheContainer controlClass];
        if( [controlClass isSubclassOfClass:[IXBaseControl class]] )
        {
            [IXControlCacheContainer populateControl:[[controlClass alloc] init]
                               controlCacheContainer:controlCacheContainer
                                     completionBlock:^(BOOL didSucceed, IXBaseControl *populatedControl, NSError *error) {
                                         
                                         if( didSucceed && populatedControl )
                                         {
                                             completionBlock(YES,populatedControl,nil);
                                         }
                                         else
                                         {
                                             completionBlock(NO,nil,error);
                                         }
                                     }];
        }
        else
        {
            completionBlock(NO,nil,[NSError errorWithDomain:@"ControlCacheContainer control type is invalid." code:0 userInfo:nil]);
        }
    }
    else
    {
        completionBlock(NO,nil,[NSError errorWithDomain:@"ControlCacheContainer is nil. Cannot create control." code:0 userInfo:nil]);
    }
}

+(void)createControlWithPathToJSON:(NSString*)pathToJSON
                         loadAsync:(BOOL)loadAsync
                   completionBlock:(IXCreateControlCompletionBlock)completionBlock
{
    [IXControlCacheContainer controlCacheContainerWithJSONAtPath:pathToJSON
                                                       loadAsync:loadAsync
                                                 completionBlock:^(BOOL didSucceed, IXControlCacheContainer *controlCacheContainer, NSError *error) {
                                                     
                                                     if( didSucceed ) {
                                                         [IXControlCacheContainer createControlWithControlCacheContainer:controlCacheContainer
                                                                                                         completionBlock:completionBlock];
                                                     } else {
                                                         completionBlock(NO,nil,error);
                                                     }
                                                 }];
}

+(void)controlCacheContainerWithJSONAtPath:(NSString*)pathToJSON
                                 loadAsync:(BOOL)loadAsync
                           completionBlock:(IXGetControlCacheContainerCompletionBlock)completionBlock
{
    IXControlCacheContainer* cachedControlCacheContainer = [sControlCacheContainerCache objectForKey:pathToJSON];
    if( cachedControlCacheContainer == nil )
    {
        [[IXDataGrabber sharedDataGrabber] grabJSONFromPath:pathToJSON asynch:loadAsync shouldCache:NO completionBlock:^(id jsonObject, NSString* stringValue, NSError *error) {
            
            if( [jsonObject isKindOfClass:[NSDictionary class]] )
            {
                NSDictionary* controlJSONDictionary = jsonObject[kIXViewControlRef];
                if( controlJSONDictionary == nil )
                {
                    controlJSONDictionary = jsonObject;
                }
                
                NSMutableDictionary* propertiesDictionary = [NSMutableDictionary dictionaryWithDictionary:controlJSONDictionary[kIX_ATTRIBUTES]];
                
                NSString* controlType = controlJSONDictionary[kIX_TYPE];
                if( !controlType ) {
                    controlType = propertiesDictionary[kIX_TYPE];
                }
                NSString* controlStyleClass = controlJSONDictionary[kIX_STYLE];
                if( !controlStyleClass ) {
                    controlStyleClass = propertiesDictionary[kIX_STYLE];
                }
                id controlID = controlJSONDictionary[kIX_ID];
                if( controlID && [propertiesDictionary objectForKey:kIX_ID] == nil ) {
                    [propertiesDictionary setObject:controlID forKey:kIX_ID];
                }
                
                IXPropertyContainer* propertyContainer = [IXPropertyContainer propertyContainerWithJSONDict:propertiesDictionary];
                
                IXActionContainer* actionContainer = [IXActionContainer actionContainerWithJSONActionsArray:controlJSONDictionary[kIX_ACTIONS]];
                NSArray* childConfigControls = [IXBaseControlConfig controlConfigsWithJSONControlArray:controlJSONDictionary[kIX_CONTROLS]];
                NSArray* dataProviderConfigs = [IXBaseDataProviderConfig dataProviderConfigsWithJSONArray:controlJSONDictionary[kIX_DATASOURCES]];
                
                IXControlCacheContainer* controlCacheContainer = [[IXControlCacheContainer alloc] initWithControlType:controlType
                                                                                                           styleClass:controlStyleClass
                                                                                                    propertyContainer:propertyContainer
                                                                                                      actionContainer:actionContainer
                                                                                                  childConfigControls:childConfigControls
                                                                                                  dataProviderConfigs:dataProviderConfigs];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    [sControlCacheContainerCache setObject:controlCacheContainer forKey:pathToJSON];
                });
                
                completionBlock(YES,controlCacheContainer,nil);
            }
            else
            {
                completionBlock(NO,nil,error);
                
                IX_LOG_ERROR(@"ERROR from %@ in %@ : Grabbing custom control JSON at path %@ with error : %@",THIS_FILE,THIS_METHOD,pathToJSON,[error description]);
            }
        }];
    }
    else
    {
        completionBlock(YES,cachedControlCacheContainer,nil);
    }
}

+(void)populateControl:(IXBaseControl*)control withJSONAtPath:(NSString*)pathToJSON loadAsync:(BOOL)loadAsync completionBlock:(IXPopulateControlCompletionBlock)completionBlock
{
    [IXControlCacheContainer controlCacheContainerWithJSONAtPath:pathToJSON loadAsync:loadAsync completionBlock:^(BOOL didSucceed, IXControlCacheContainer *controlCacheContainer, NSError *error) {
                                                        
        if( didSucceed && controlCacheContainer != nil )
        {
            [IXControlCacheContainer populateControl:control
                               controlCacheContainer:controlCacheContainer
                                     completionBlock:completionBlock];
        }
        else
        {
            completionBlock(NO,control,error);
        }
    }];
}

@end
