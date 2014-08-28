//
// Created by Michael Seghers on 28/08/14.
// Copyright (c) 2014 AppFoundry. All rights reserved.
//

#import "TabBarConfiguration.h"
#import "DetailViewModel.h"
#import "DefaultDetailViewModel.h"


@implementation TabBarConfiguration {

}

- (id<DetailViewModel>) createSingletonDetailViewModel {
    return [[DefaultDetailViewModel alloc] init];
}
@end