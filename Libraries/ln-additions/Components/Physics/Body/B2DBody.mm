/*!
    @header B2DBody
    @copyright LnStudio
    @updated 15/07/2013
    @author lingnan
*/

#import "CCComponent.h"
#import "B2DBody_protected.h"
#import "B2DWorld_protected.h"
#import "b2Fixture.h"
#import "B2DFixture_protected.h"
#import "CCNode+LnAdditions.h"

@implementation B2DBody {
    b2BodyDef *_bodyDef;
}


+ (id)bodyWithB2Body:(b2Body *)body {
    return [[self alloc] initWithB2Body:body];
}

+ (id)bodyFromB2Body:(b2Body *)body {
    if (!body)
        return nil;
    id b = (__bridge id) body->GetUserData();
    return [b isKindOfClass:[self class]] ? b : nil;
}

- (id)initWithB2Body:(b2Body *)body {
    NSAssert(body, @"Cannot initialize a B2DBody with a NULL b2Body pointer");
    id b = [self.class bodyFromB2Body:body];
    if (b) {
        self = b;
    } else if (self = [super init]) {
        self.body = body;
    }
    return self;
}

- (void)bindB2Body:(b2Body *)body toUserData:(void *)data {
    body->SetUserData(data);
}

- (void)enumerateFixturesInB2Body:(b2Body *)body withBlock:(void (^)(b2Fixture *fixture))block {
    b2Fixture *fix = body->GetFixtureList();
    while (fix) {
        block(fix);
        fix = fix->GetNext();
    }
}

- (void)setBody:(b2Body *)body {
    if (_body != body) {
        if (_body) {
            [self bindB2Body:_body toUserData:nil];
            // should we loop through all the fixture defs and set the userdata to nil?

            // should we destroy the body?
//            [(B2DWorld *) self.world destroyBody:_body];
            // should we delete the body?
            // delete _body;
            // save the bodyDef if the body is going to be niled.
            if (!body) {
                self.bodyDef = self.currentBodyDef;
            }
            // we need to nil all the fixtures
            for (B2DFixture *fix in self.fixtures) {
                fix.fix = nil;
            }
        }
        _body = body;
        if (body) {
            // we should check here if the body is already associated with
            // another B2DBody object
            id b = [self.class bodyFromB2Body:body];
            if (b) {
                NSAssert([b isKindOfClass:[B2DBody class]], @"the body is associated with some unknown class");
                ((B2DBody *)b).body = nil;
            }
            [self bindB2Body:body toUserData:(__bridge void *)self];
            self.bodyDef = nil;

            if (body->GetFixtureList()) {
                // if the body has fixtures; then that will override
                // the existing fixtures
                [self.fixtures removeAllObjects];
                // convert all the fixtures in the body into cached fixtures..
                [self enumerateFixturesInB2Body:body withBlock:^(b2Fixture *fixture) {
                    // add the fixture into self
                    // these steps will automatically wire up with top structure
                    [B2DFixture fixtureWithB2Fixture:fixture];
                }];
            } else {
                // add all the current fixtures
                for (B2DFixture *fix in self.fixtures)
                    fix.fix = self.body->CreateFixture(fix.currentFixtureDef);
            }
        }
        if (!self.bodyWorldInSync) {
            // default to instantiate a B2DWorld upper level
            if (body)
                self.world = [B2DWorld worldWithB2World:body->GetWorld()];
            else
                self.world = nil;
        }
    }
}

- (b2BodyDef *)bodyDef {
    if (!_bodyDef)
        _bodyDef = new b2BodyDef();
    return _bodyDef;
}

- (void)setBodyDef:(b2BodyDef *)bodyDef {
    if (bodyDef != _bodyDef) {
       // delete the old bodyDef
        delete _bodyDef;
        _bodyDef = bodyDef;
    }
}

- (void)setPosition:(CGPoint)position {
    // first get the position relative to the world
    // set the relative position in the physical world
    self.worldPosition = CGPointApplyAffineTransform(position, [self hostParentToWorldTransform]);
}

- (CGPoint)worldPosition {
    return [self.world CGPointFromb2Vec2:self.realPhysicalPosition];
}

- (void)setWorldPosition:(CGPoint)worldPosition {
    self.realPhysicalPosition = [self.world b2Vec2FromCGPoint:worldPosition];
}

- (b2Vec2)realPhysicalPosition {
    return self.body ? _body->GetPosition() : self.bodyDef->position;
}

- (void)setRealPhysicalPosition:(b2Vec2)realPhysicalPosition {
    if (self.body) {
        self.body->SetTransform(realPhysicalPosition, self.angle);
    } else {
        self.bodyDef->position = realPhysicalPosition;
    }
}

- (float)angle {
    return self.body ? self.body->GetAngle() : self.bodyDef->angle;
}

- (void)setAngle:(float)angle {
    if (self.body)
        self.body->SetTransform(self.realPhysicalPosition, angle);
    else
        self.bodyDef->angle = angle;
}

- (CGPoint)velocity {
    return CGPointApplyAffineTransform(self.worldVelocity, [self worldToHostParentTransform]);
}

- (void)setVelocity:(CGPoint)velocity {
    self.worldVelocity = CGPointApplyAffineTransform(velocity, [self hostParentToWorldTransform]);
}

// velocity in the CC sense
- (CGPoint)worldVelocity {
    return [self.world CGPointFromb2Vec2:self.linearVelocity];
}

- (void)setWorldVelocity:(CGPoint)velocity {
    self.linearVelocity = [self.world b2Vec2FromCGPoint:velocity];
}

- (b2Vec2)linearVelocity {
    return self.body ? self.body->GetLinearVelocity() : self.bodyDef->linearVelocity;
}

- (void)setLinearVelocity:(b2Vec2)linearVelocity {
    if (self.body)
        self.body->SetLinearVelocity(linearVelocity);
    else
        self.bodyDef->linearVelocity = linearVelocity;
}

- (float)angularVelocity {
    return self.body ? self.body->GetAngularVelocity() : self.bodyDef->angularVelocity;
}

- (void)setAngularVelocity:(float)angularVelocity {
    if (self.body)
        self.body->SetAngularVelocity(angularVelocity);
    else
        self.bodyDef->angularVelocity = angularVelocity;
}

- (float)linearDamping {
    return self.body ? self.body->GetLinearDamping() : self.bodyDef->linearDamping;
}

- (void)setLinearDamping:(float)linearDamping {
    if (self.body)
        self.body->SetLinearDamping(linearDamping);
    else
        self.bodyDef->linearDamping = linearDamping;
}

- (float)angularDamping {
    return self.body ? self.body->GetAngularDamping() : self.bodyDef->angularDamping;
}

- (void)setAngularDamping:(float)angularDamping {
    if (self.body)
        self.body->SetAngularDamping(angularDamping);
    else
        self.bodyDef->angularDamping = angularDamping;
}

- (BOOL)allowSleep {
    return self.body ? self.body->IsSleepingAllowed() : self.bodyDef->allowSleep;
}

- (void)setAllowSleep:(BOOL)allowSleep {
    if (self.body)
        self.body->SetSleepingAllowed(allowSleep);
    else
        self.bodyDef->allowSleep = allowSleep;
}

- (BOOL)awake {
    return self.body ? self.body->IsAwake() : self.bodyDef->awake;
}

- (void)setAwake:(BOOL)awake {
    if (self.body)
        self.body->SetAwake(awake);
    else
        self.bodyDef->awake = awake;
}

- (BOOL)fixedRotation {
    return self.body ? self.body->IsFixedRotation() : self.bodyDef->fixedRotation;
}

- (void)setFixedRotation:(BOOL)fixedRotation {
    if (self.body)
        self.body->SetFixedRotation(fixedRotation);
    else
        self.bodyDef->fixedRotation = fixedRotation;
}

- (BOOL)bullet {
    return self.body ? self.body->IsBullet() : self.bodyDef->bullet;
}

- (void)setBullet:(BOOL)bullet {
    if (self.body)
        self.body->SetBullet(bullet);
    else
        self.bodyDef->bullet = bullet;
}

- (BOOL)active {
    return self.body ? self.body->IsActive() : self.bodyDef->active;
}

- (void)setActive:(BOOL)active {
    if (self.body)
        self.body->SetActive(active);
    else
        self.bodyDef->active = active;
}

- (float)gravityScale {
    return self.body ? self.body->GetGravityScale() : self.bodyDef->gravityScale;
}

- (void)setGravityScale:(float)gravityScale {
    if (self.body)
        self.body->SetGravityScale(gravityScale);
    else
        self.bodyDef->gravityScale = gravityScale;
}

- (BOOL)bodyWorldInSync {
   return (!self.body && !self.world) || ([B2DWorld worldFromB2World:self.body->GetWorld()] == self.world);
}

- (void)dealloc {
    self.bodyDef = nil;
    self.body = nil;
}

- (b2BodyDef *)currentBodyDef {
    b2BodyDef *def;
    if (self.body) {
        NSAssert(!self.bodyDef, @"Inconsistent states. BodyDef should have been deleted if body is present");
        def = new b2BodyDef();
        def->position = _body->GetPosition();
        def->angle = _body->GetAngle();
        def->linearVelocity = _body->GetLinearVelocity();
        def->angularVelocity = _body->GetAngularVelocity();
        def->linearDamping = _body->GetLinearDamping();
        def->angularDamping = _body->GetAngularDamping();
        def->allowSleep = _body->IsSleepingAllowed();
        def->awake = _body->IsAwake();
        def->fixedRotation = _body->IsFixedRotation();
        def->bullet = _body->IsBullet();
        def->active = _body->IsActive();
        def->gravityScale = _body->GetGravityScale();
    } else {
        def = self.bodyDef;
    }
    return def;
}

/** This will allocate a new def on the heap; remember to memory manage it */
- (b2FixtureDef *)fixtureDefFromFixture:(const b2Fixture *)fixture {
    b2FixtureDef *def = new b2FixtureDef;
    // get the attributes one by one
    def->density = fixture->GetDensity();
    def->shape = fixture->GetShape();
    def->filter = fixture->GetFilterData();
    def->friction = fixture->GetFriction();
    def->isSensor = fixture->IsSensor();
    def->restitution = fixture->GetRestitution();
    def->userData = fixture->GetUserData();
    return def;
}

#pragma mark - Fixture Operations

-(void) addFixture:(B2DFixture *)fixture {
    // check if the fixture is already part of the body.. ?
    if (fixture.body != self) {
        if (fixture.body)
            [fixture.body removeFixture:fixture];
        //// setting the delegate
        [fixture setBodyDirect:self];
        //// setting the fix
        // sync the fixture and body definition within
        if (self.body) {
            if (!fixture.fix || self.body != fixture.fix->GetBody()) {
                fixture.fix = self.body->CreateFixture(fixture.currentFixtureDef);
            }
        } else {
            fixture.fix = nil;
        }
        // save this fixture in a set
        [self.fixtures addObject:fixture];
    }
}

-(void) removeFixture:(B2DFixture *)fixture {
    if (fixture.body == self) {
        // remove the fixture from the body
        if (self.body)
            self.body->DestroyFixture(fixture.fix);
        //// setting the delegate
        [fixture setBodyDirect:nil];
        //// setting fix
        // we also need to set the fixture.fix to nil
        // as an fix instance without a body would be meaningless
        fixture.fix = nil;
        [self.fixtures removeObject:fixture];
    }
}

- (NSMutableSet *)fixtures {
    if (!_fixtures)
        _fixtures = [NSMutableSet set];
    return _fixtures;
}

#pragma mark - Update

- (BOOL)activated {
    return [super activated] && self.body != nil;
}

+ (NSSet *)keyPathsForValuesAffectingActivated {
    NSMutableSet *set = [NSMutableSet setWithSet:[super keyPathsForValuesAffectingActivated]];
    [set addObject:@"body"];
    return set;
}

- (void)activate {
    [super activate];
    // we didn't add the Initial option because the b2body position has a higher priority
//    [self.host addObserver:self
//                forKeyPath:@"position"
//                   options:nil
//                   context:nil];
    [self scheduleUpdate];
}

- (void)deactivate {
    [super deactivate];
//    [self.host removeObserver:self forKeyPath:@"position"];
    [self unscheduleUpdate];
}

#pragma mark - Unit conversion (depending on the world)

//- (void)observeValueForKeyPath:(NSString *)keyPath
//                      ofObject:(id)object
//                        change:(NSDictionary *)change
//                       context:(void *)context {
//    if ([keyPath isEqualToString:@"position"]) {
//        self.position = self.host.position;
//    } else {
//        [super observeValueForKeyPath:keyPath
//                             ofObject:object
//                               change:change
//                              context:context];
//    }
//}

- (void)update:(ccTime)step {
    CGPoint ccpos = [self.world CGPointFromb2Vec2:self.body->GetPosition()];
    self.host.nodePosition = CGPointApplyAffineTransform(ccpos, [self worldToHostParentTransform]);
    // this might not consider the relative rotation of layered relationships
    self.host.rotation = -1 * CC_RADIANS_TO_DEGREES(self.body->GetAngle());
}

- (id)copyWithZone:(NSZone *)zone {
    B2DBody *copy = (B2DBody *) [super copyWithZone:zone];

    if (copy != nil) {
        copy->_bodyDef = self.currentBodyDef;
        copy->_fixtures = [[NSMutableSet alloc] initWithSet:self.fixtures copyItems:YES];
    }

    return copy;
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@"; b2body pointer = %p", self.body];
}

@end
