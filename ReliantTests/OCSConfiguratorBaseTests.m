//
//  OCSConfiguratorBaseTests.m
//  Reliant
//
//  Created by Michael Seghers on 25/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <OCMock/OCMock.h>

#import "OCSApplicationContext.h"
#import "OCSConfiguratorBase.h"
#import "OCSDefinition.h"

#import "OCSConfiguratorBaseTests.h"

@interface DummyBaseConfiguratorExtension : OCSConfiguratorBase

@end

@implementation DummyBaseConfiguratorExtension

- (id) internalObjectForKey:(NSString *) keyOrAlias inContext:(OCSApplicationContext *) context {
    return nil;
}
- (void) internalContextLoaded:(OCSApplicationContext *) context {
    
}

@end

@interface BadDummyBaseConfiguratorExtension : OCSConfiguratorBase

@end

@implementation BadDummyBaseConfiguratorExtension

@end

@interface OCSConfiguratorBase (TestAdditions)

- (void) addDefinition:(OCSDefinition *) def;

@end

@implementation OCSConfiguratorBase (TestAdditions)

- (void) addDefinition:(OCSDefinition *) def  {
    [_definitionRegistry setObject:def forKey:def.key];
}

@end



@implementation OCSConfiguratorBaseTests {
    id dummyConfigurator;
    id badDummyConfigurator;
    id context;
}

- (void) setUp {
    [super setUp];

    dummyConfigurator = [OCMockObject partialMockForObject:[[[DummyBaseConfiguratorExtension alloc] init] autorelease]];
    badDummyConfigurator = [OCMockObject partialMockForObject:[[[BadDummyBaseConfiguratorExtension alloc] init] autorelease]];
    context = [OCMockObject mockForClass:[OCSApplicationContext class]];
}

- (void) tearDown {
    dummyConfigurator = nil;
    context = nil;
    [super tearDown];
}

- (void) testObjectForKeyBeforeLoaded {
    id result = [dummyConfigurator objectForKey:@"SomeKey" inContext:context];
    
    STAssertNil(result, @"Result should always be nil before the context has been marked as loaded");
}

- (void) testObjectForKeyAfterLoaded {
    BOOL noo = NO;
    [[[dummyConfigurator stub] andReturnValue:OCMOCK_VALUE(noo)] initializing];
    [[[dummyConfigurator expect] andReturn:@"ReturnedObject"] internalObjectForKey:@"SomeKey" inContext:context];
    
    id result = [dummyConfigurator objectForKey:@"SomeKey" inContext:context];
    
    [dummyConfigurator verify];
    
    STAssertEqualObjects(result, @"ReturnedObject", @"The result of the internal function should have been returned");
}


- (void) testContextLoadedBadSubclass {
    STAssertThrowsSpecificNamed([badDummyConfigurator contextLoaded:context], NSException, @"OCSConfiguratorException", @"OCSConfiguratorException expected when directly calling this (abstract)");
}

- (void) testContextLoadedWithGoodSubclass {
    [[dummyConfigurator expect] internalContextLoaded:context];
    
    STAssertTrue([dummyConfigurator initializing], @"Initializing flag should be true by default.");
    
    [dummyConfigurator contextLoaded:context];
    
    STAssertFalse([dummyConfigurator initializing], @"Initializing flag should have been switched off.");
    
    [dummyConfigurator verify];
}

- (void) addDefinitions:(OCSConfiguratorBase *) configurator {
    OCSDefinition *lazy = [[[OCSDefinition alloc] init] autorelease];
    lazy.singleton = YES;
    lazy.lazy = YES;
    lazy.key = @"LazySingletonKey";
    
    [configurator addDefinition:lazy];
    
    OCSDefinition *eager = [[[OCSDefinition alloc] init] autorelease];
    eager.singleton = YES;
    eager.lazy = NO;
    eager.key = @"EagerSingletonKey";
    
    [configurator addDefinition:eager];
    
    OCSDefinition *prototype = [[[OCSDefinition alloc] init] autorelease];
    prototype.singleton = NO;
    prototype.key = @"PrototypeKey";
    
    [configurator addDefinition:prototype];
}

- (void) testContextLoadedBadSubclassHavingDefinitions {
    [self addDefinitions:badDummyConfigurator];
    
    STAssertThrowsSpecificNamed([badDummyConfigurator contextLoaded:context], NSException, @"OCSConfiguratorException", @"OCSConfiguratorException expected when directly calling this (abstract)");
}

- (void) testContextLoadedWithGoodSubclassHavingDefinitions {
    [self addDefinitions:dummyConfigurator];

    NSObject *fakeObject = [[NSObject alloc] init];
    [[[dummyConfigurator expect] andReturn:fakeObject] internalObjectForKey:@"EagerSingletonKey" inContext:context];
    
    
    [[dummyConfigurator expect] internalContextLoaded:context];
    
    [[context expect] performInjectionOn:fakeObject];
    
    STAssertTrue([dummyConfigurator initializing], @"Initializing flag should be true by default.");
    
    [dummyConfigurator contextLoaded:context];
    
    STAssertFalse([dummyConfigurator initializing], @"Initializing flag should have been switched off.");
    
    [dummyConfigurator verify];
    [context verify];
}







@end
