//
//  OCSConfiguratorFromClassTests.m
//  Reliant
//
//  Created by Michael Seghers on 17/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <OCMock/OCMock.h>

#import "OCSConfiguratorFromClassTests.h"

#import "OCSConfiguratorFromClass.h"
#import "OCSApplicationContext.h"

@interface DummyConfigurator : NSObject

@end

@interface ObjectWithInjectables : NSObject

@property (nonatomic, retain) id verySmartName;

- (id) initWithVerySmartName:(id) verySmartName;

@end

@interface ExtendedObjectWithInjectables : ObjectWithInjectables

@property (nonatomic, retain) id unbelievableOtherSmartName;

@end


@implementation OCSConfiguratorFromClassTests {
    OCSConfiguratorFromClass *configurator;
    
    int verySmartNameInjected;
    int unbelievableOtherSmartNameInjected;
    int superInjected;
    int extendedInjected;
}

- (void) setUp {
    [super setUp];
    
    // Set-up code here.
    verySmartNameInjected = 0;
    unbelievableOtherSmartNameInjected = 0;
    superInjected = 0;
    extendedInjected = 0;
    
    configurator = [[OCSConfiguratorFromClass alloc] initWithClass:[DummyConfigurator class]];
}

- (void) tearDown {
    // Tear-down code here.
    configurator = nil;
    
    [super tearDown];
}

- (void) testBeforeLoaded {
    id context = [OCMockObject mockForClass:[OCSApplicationContext class]];
    
    id object = [configurator objectForKey:@"VerySmartName" inContext:context];
    STAssertNil(object, @"No objects should ever be returned when still initializing");
    
}

- (void) doTestSingletonRetrievalWithKey:(NSString *) key andAlias1:(NSString *) alias1 andAlias2:(NSString *) alias2 inContext:(OCSApplicationContext *) context {
    id singleton = [configurator objectForKey:key inContext:context];
    STAssertNotNil(singleton, @"Singleton %@ shoud be available", key);
    STAssertTrue(singleton == [configurator objectForKey:key inContext:context], @"Retrieving a singleton by key from the configurator should always return the same instance");
    STAssertTrue(singleton == [configurator objectForKey:alias1 inContext:context], @"Retrieving a singleton by alias from the configurator should always return the same instance");
    STAssertTrue(singleton == [configurator objectForKey:alias2 inContext:context], @"Retrieving a singleton by alias from the configurator should always return the same instance");
}

- (void) testAfterLoaded {
    id context = [OCMockObject mockForClass:[OCSApplicationContext class]];
    
    //3 singletons to be loaded -> 3 injection attempts
    //Remaining object is not a singleton and should not have been loaded, nor injected after a contetLoaded
    for (int i = 0; i < 3; i++) {
        [[context expect] performInjectionOn:[OCMArg checkWithSelector:@selector(checkInjection:) onObject:self]];
    }
    
    [configurator contextLoaded:context];
    
    STAssertEquals(verySmartNameInjected, 1, @"Very smart object should have been injected by now");
    STAssertEquals(superInjected, 1, @"Super object should have been injected by now");
    STAssertEquals(extendedInjected, 1, @"Extended object should have been injected by now");
    STAssertEquals(unbelievableOtherSmartNameInjected, 0, @"Ubelievable object should not have been injected by now");
    
    //Now fetching the singletons, with aliases should work, they should not be re-injected
    
    [self doTestSingletonRetrievalWithKey:@"VerySmartName" andAlias1:@"verySmartName" andAlias2:@"VERYSMARTNAME" inContext:context];
    [self doTestSingletonRetrievalWithKey:@"Super" andAlias1:@"super" andAlias2:@"SUPER" inContext:context];
    [self doTestSingletonRetrievalWithKey:@"Extended" andAlias1:@"extended" andAlias2:@"EXTENDED" inContext:context];
    
    [[context expect] performInjectionOn:[OCMArg checkWithSelector:@selector(checkInjection:) onObject:self]];
    
    id unbelievableObject = [[configurator objectForKey:@"UnbelievableOtherSmartName" inContext:context] retain];
    
    STAssertNotNil(unbelievableObject, @"Unbelievable object shoud be available");
    
    STAssertEquals(verySmartNameInjected, 1, @"Very smart object should have been injected by now");
    STAssertEquals(superInjected, 1, @"Super object should have been injected by now");
    STAssertEquals(extendedInjected, 1, @"Extended object should have been injected by now");
    STAssertEquals(unbelievableOtherSmartNameInjected, 1, @"Ubelievable object should not have been injected by now");
    
    //Re-fetch a new instance object, it should always be a new instance which has been injected.
    [[context expect] performInjectionOn:[OCMArg checkWithSelector:@selector(checkInjection:) onObject:self]];
    
    
    id otherUnbelievableObject = [[configurator objectForKey:@"UnbelievableOtherSmartName" inContext:context] retain];
    STAssertFalse(unbelievableObject == otherUnbelievableObject, @"New instance objects should always be different instances");
    STAssertEquals(verySmartNameInjected, 1, @"Very smart object should have been injected by now");
    STAssertEquals(superInjected, 1, @"Super object should have been injected by now");
    STAssertEquals(extendedInjected, 1, @"Extended object should have been injected by now");
    STAssertEquals(unbelievableOtherSmartNameInjected, 2, @"Ubelievable object should not have been injected again");
    
    //We also know by now that the "wrong" configurator methods did not yield an object...
    
    [context verify];
    
    [unbelievableObject release];
    [otherUnbelievableObject release];
    
    
}

- (BOOL) checkInjection:(id<NSObject>) injectedObject {
    BOOL result = YES;
    
    if ([injectedObject isMemberOfClass:[NSObject class]]) {
        verySmartNameInjected++;
    } else if ([injectedObject isKindOfClass:[NSArray class]]) {
        unbelievableOtherSmartNameInjected++;
    } else if ([injectedObject isMemberOfClass:[ObjectWithInjectables class]]) {
        superInjected++;
    } else if ([injectedObject isMemberOfClass:[ExtendedObjectWithInjectables class]]) {
        extendedInjected++;
    } else {
        result = NO;
    }
                                          
    return result;
}


@end

@implementation DummyConfigurator 

- (id) createSingletonVerySmartName {
    return [[[NSObject alloc] init] autorelease];
}

- (id) createNewInstanceUnbelievableOtherSmartName {
    return [[[NSMutableArray alloc] init] autorelease];
}

- (ObjectWithInjectables *) createSingletonSuper {
    return [[[ObjectWithInjectables alloc] initWithVerySmartName:[self createSingletonVerySmartName]] autorelease];
}

- (ExtendedObjectWithInjectables *) createSingletonExtended {
    return [[[ExtendedObjectWithInjectables alloc] init] autorelease];
}

- (id) createWithBadName {
    return @"WRONG";
}


- (id) createSingletonSomeObjectWithSuper:(ObjectWithInjectables *) super andExtended:(ExtendedObjectWithInjectables *) extended {
    return @"WRONG AGAIN";
}

- (id) createNewInstanceWithParameter:(id) param {
    return @"WRONG AGAIN AGAIN";
}


@end

@implementation ObjectWithInjectables

@synthesize verySmartName;

- (id) initWithVerySmartName:(id)averySmartName {
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