//
//  NSObject+MMAnonymousClass.m
//  Runtime
//
//  Created by flanker on 21.02.13.
//  Copyright (c) 2013 LOL. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "NSObject+MMAnonymousClass.h"

NSString *const kMMExeptionMethodError = @"MMExeptionMethodError";
NSString *const kMMExeptionSelector = @"MMExeptionSelector";

@implementation NSObject (MMAnonymousClass)

+ (Class)subclassWithReuseID:(NSString *)reuseID
                 configBlock:(void(^)(Class class))block
{
    reuseID = [[reuseID componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
    
    Class ret = NSClassFromString(reuseID);
    if (ret == nil) {
        ret = objc_allocateClassPair([self class], reuseID.UTF8String, 0);
        block(ret);
        objc_registerClassPair(ret);
    }
    
    return ret;
}

+ (void)addMethod:(SEL)sel fromProtocol:(Protocol *)p blockImp:(id)block {
    struct objc_method_description descript;
    for (NSNumber *b in @[@NO,@YES]) {
        descript = protocol_getMethodDescription(p, sel, b.boolValue, YES);
        if (descript.types) {
            [self addMethod:sel blockImp:block types:descript.types];
            return;
        }
    }
    
    NSString *reason = [NSString stringWithFormat:@"Method (%@) can't be found. Please, check protocol",NSStringFromSelector(sel)];
    @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
}

+ (void)addClassMethod:(SEL)sel blockImp:(id)block {
    Method method = class_getInstanceMethod(self, sel);
    [self addMethod:sel blockImp:block types:method_getTypeEncoding(method)];
}

+ (void)addMethod:(SEL)sel blockImp:(id)block types:(const char *)types {
    Method method = class_getInstanceMethod(self, sel);
    if (method) {
        [self overrideMethod:sel blockImp:block];
        return;
    } else {
        IMP newImp = imp_implementationWithBlock(block);
        if (class_addMethod(self, sel, newImp, types))
            return;
    }
    
    NSString *reason = [NSString stringWithFormat:@"Method (%@) can't be added. Please, check params",NSStringFromSelector(sel)];
    @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
}

+ (void)overrideMethod:(SEL)sel blockImp:(id)block {
    Method method = class_getInstanceMethod(self, sel);
    if (method) {
        class_replaceMethod(self, sel, imp_implementationWithBlock(block), method_getTypeEncoding(method));
        return;
    }
    
    NSString *reason = [NSString stringWithFormat:@"Method (%@) can't be added. Please, check params",NSStringFromSelector(sel)];
    @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
}

+ (void)removeMethod:(SEL)sel
{
    Method method = class_getClassMethod(self, sel);
    if (method != nil) {
        method_setImplementation(method,(IMP)_objc_msgForward);
        return;
    }
    
    NSString *reason = [NSString stringWithFormat: @"Method (%@) can't be removed. Method not found",NSStringFromSelector(sel)];
    @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
}

+ (void)removeClassMethod:(SEL)sel
{
    Method method = class_getInstanceMethod(self, sel);
    if (method != nil) {
        method_setImplementation(method,(IMP)_objc_msgForward);
        return;
    }
    
    NSString *reason = [NSString stringWithFormat: @"Method (%@) can't be removed. Method not found",NSStringFromSelector(sel)];
    @throw [NSException exceptionWithName:kMMExeptionMethodError reason:reason userInfo:@{kMMExeptionSelector:NSStringFromSelector(sel)}];
}

@end
