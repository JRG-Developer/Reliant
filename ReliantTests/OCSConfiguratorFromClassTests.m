//
//  OCSConfiguratorFromClassTests.m
//  Reliant
//
//  Created by Michael Seghers on 17/05/12.
//  Copyright (c) 2012 iDA MediaFoundry. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>
#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#if (TARGET_OS_IPHONE) 
#import <UIKit/UIApplication.h>
#endif


#import "OCSConfiguratorFromClassTests.h"

#import "OCSConfiguratorFromClass.h"
#import "OCSApplicationContext.h"

@interface DummyConfigurator (SomeDummyCategory)

@end

@interface ObjectWithInjectables : NSObject

@property (nonatomic, strong) NSObject *verySmartName;

- (id) initWithVerySmartName:(NSObject *) verySmartName;

@end

@interface ExtendedObjectWithInjectables : ObjectWithInjectables

@property (nonatomic, strong) id unbelievableOtherSmartName;

@end

@interface BadAliasFactoryClass : NSObject

@end



@implementation OCSConfiguratorFromClassTests {
    OCSConfiguratorFromClass *configurator;
    
    int verySmartNameInjected;
    int unbelievableOtherSmartNameInjected;
    int lazyOneInjected;
    int superInjected;
    int extendedInjected;
    int categoryInjected;
    int externalCategoryInjected;
}

- (void) setUp {
    [super setUp];
    configurator = [[OCSConfiguratorFromClass alloc] initWithClass:[DummyConfigurator class]];
}

- (void) tearDown {
    // Tear-down code here.
    configurator = nil;
    
    [super tearDown];
}

- (void) testBeforeLoaded {
    OCSApplicationContext *context = mock([OCSApplicationContext class]);
    id object = [configurator objectForKey:@"VerySmartName" inContext:context];
    STAssertNil(object, @"No objects should ever be returned when still initializing");
    
}

- (id) doTestSingletonRetrievalWithKey:(NSString *) key andAliases:(NSArray *) aliases inContext:(OCSApplicationContext *) context {
    id singleton = [configurator objectForKey:key inContext:context];
    STAssertNotNil(singleton, @"Singleton %@ shoud be available", key);
    STAssertTrue(singleton == [configurator objectForKey:key inContext:context], @"Retrieving a singleton by key from the configurator should always return the same instance");
    [aliases enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        STAssertTrue(singleton == [configurator objectForKey:obj inContext:context], @"Retrieving a singleton by alias from the configurator should always return the same instance");
        
    }];
    return singleton;
}


- (void) testLoadShouldInjectLoadedObjects {
    OCSApplicationContext *context = mock([OCSApplicationContext class]);
    [configurator contextLoaded:context];
    [verifyCount(context, times(5)) performInjectionOn:anything()];
    
    //TODO check which methods were called exactly, after refactoring the object storage to the context / scopes
}

- (void) testSameInstanceIsReturnedForKeyAndAliases {
    OCSApplicationContext *context = mock([OCSApplicationContext class]);
    [configurator contextLoaded:context];
    [self doTestSingletonRetrievalWithKey:@"Super" andAliases:@[@"super", @"SUPER"] inContext:context];
    [self doTestSingletonRetrievalWithKey:@"Extended" andAliases:@[@"extended", @"EXTENDED"] inContext:context];
}

- (void) testDifferentInjectedObjectsShouldHaveSameInstanceForSingleton {
    OCSApplicationContext *context = mock([OCSApplicationContext class]);
    [configurator contextLoaded:context];
    NSObject *verySmartItself = [configurator objectForKey:@"VerySmartName" inContext:context];
    ObjectWithInjectables *owi = [configurator objectForKey:@"Super" inContext:context];
    STAssertTrue(verySmartItself == owi.verySmartName, @"The constructor injected instance should be the same as the instance created by the base method");
}

- (void) testRetrievePrototypeObject {
    OCSApplicationContext *context = mock([OCSApplicationContext class]);
    [configurator contextLoaded:context];
    NSMutableArray *firstProto = [configurator objectForKey:@"UnbelievableOtherSmartName" inContext:context];
    STAssertNotNil(firstProto, @"Prototype should have been created");
    NSMutableArray *secondProto = [configurator objectForKey:@"UnbelievableOtherSmartName" inContext:context];
    STAssertNotNil(secondProto, @"Prototype should have been created");
    STAssertFalse(firstProto == secondProto, @"Prototype instances should be different");
}

- (void) testLazyLoading {
    OCSApplicationContext *context = mock([OCSApplicationContext class]);
    [configurator contextLoaded:context];
    NSDictionary *lazyObject = [configurator objectForKey:@"LazyOne" inContext:context];
    NSDictionary *newlyFetched = [configurator objectForKey:@"LazyOne" inContext:context];
    STAssertNotNil(lazyObject, @"lazyObject should not be nil");
    STAssertNotNil(newlyFetched, @"lazyObject should not be nil");
    STAssertTrue(lazyObject == newlyFetched, @"Instance should be the same when singleton");
    [verify(context) performInjectionOn:lazyObject];
}

#if (TARGET_OS_IPHONE)
- (void) testMemoryWarning {
    OCSApplicationContext *context = mock([OCSApplicationContext class]);
    [configurator contextLoaded:context];
    id firstVerySmartName = [self doTestSingletonRetrievalWithKey:@"VerySmartName" andAliases:[NSArray arrayWithObjects:@"verySmartName", @"VERYSMARTNAME", @"aliasForVerySmartName", @"justAnotherNameForVerySmartName", nil] inContext:context];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:[UIApplication sharedApplication]];
    id secondVerySmartName = [self doTestSingletonRetrievalWithKey:@"VerySmartName" andAliases:[NSArray arrayWithObjects:@"verySmartName", @"VERYSMARTNAME", @"aliasForVerySmartName", @"justAnotherNameForVerySmartName", nil] inContext:context];
    
    
    STAssertFalse(secondVerySmartName == firstVerySmartName, @"after memory warnings, objects should have been re-initialized");
    [verify(context) performInjectionOn:firstVerySmartName];
    [verify(context) performInjectionOn:secondVerySmartName];
}
#endif

- (void) testBadAliases {
    STAssertThrowsSpecificNamed([[OCSConfiguratorFromClass alloc] initWithClass:[BadAliasFactoryClass class]], NSException, @"OCSConfiguratorException", @"Should throw exception, aliases are bad");
}


@end

@implementation DummyConfigurator 

- (NSObject *) createEagerSingletonVerySmartName {
    return [[NSObject alloc] init];
}

- (NSArray *) aliasesForVerySmartName {
    return [NSArray arrayWithObjects:@"aliasForVerySmartName", @"justAnotherNameForVerySmartName", nil];
}

- (NSArray *) createPrototypeUnbelievableOtherSmartName {
    return [[NSMutableArray alloc] init];
}

- (NSDictionary *) createSingletonLazyOne {
    return [[NSMutableDictionary alloc] init];
}

- (ObjectWithInjectables *) createEagerSingletonSuper {
    return [[ObjectWithInjectables alloc] initWithVerySmartName:[self createEagerSingletonVerySmartName]];
}

- (ExtendedObjectWithInjectables *) createEagerSingletonExtended {
    return [[ExtendedObjectWithInjectables alloc] init];
}

- (id) createWithBadName {
    return @"WRONG";
}


- (id) createSingletonSomeObjectWithSuper:(ObjectWithInjectables *) super andExtended:(ExtendedObjectWithInjectables *) extended {
    return @"WRONG AGAIN";
}

- (id) createPrototypeWithParameter:(id) param {
    return @"WRONG AGAIN AGAIN";
}


@end

@implementation DummyConfigurator (SomeDummyCategory)

- (id) createEagerSingletonFromCategory {
    return @"FromCategory";
}

@end

@implementation ObjectWithInjectables

@synthesize verySmartName;

- (id) initWithVerySmartName:(NSObject *)averySmartName {
    self = [super init];
    if (self) {
        verySmartName = averySmartName;
    }
    return self;
}

@end


@implementation ExtendedObjectWithInjectables

@synthesize unbelievableOtherSmartName;

@end

@implementation BadAliasFactoryClass

- (id) createEagerSingleton {
    return @"Should be ignored, no key";
}

- (id) createEagerSingletonKeyValue {
    return @"KeyValue object";
}

- (NSArray *) aliasesForKeyValue {
    return [NSArray arrayWithObject:@"keyValue"];
}

@end
