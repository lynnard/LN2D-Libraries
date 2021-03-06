/*!
    @header B2DBody
    @copyright LnStudio
    @updated 15/07/2013
    @author lingnan
*/


#import "Body.h"
#import "b2Math.h"
#import "b2Body.h"

@class B2DSpace;
@class B2DFixture;
@class B2DContactListener;


// we'll preseve using the original b2d units and syntax
@interface B2DBody:Body

@property (nonatomic) b2BodyType type;
@property(nonatomic) b2Vec2 spacePhysicalPosition;
/**  the angle rotation in the convention of CC; CW is positive; in degrees */
@property (nonatomic) float rotation;
/** the angle rotation in the convention of B2D; ACW is positive; in radians */
@property (nonatomic) float angle;
@property (nonatomic) b2Vec2 linearVelocity;
@property (nonatomic) float angularVelocity;
@property (nonatomic) float linearDamping;
@property (nonatomic) float angularDamping;
@property (nonatomic) BOOL allowSleep;
@property (nonatomic) BOOL awake;
@property (nonatomic) BOOL fixedRotation;
@property (nonatomic) BOOL bullet;
@property (nonatomic) BOOL active;
@property (nonatomic) float gravityScale;
@property(nonatomic, weak) B2DSpace *space;
@property(nonatomic) B2DContactListener *contactListener;

/** a flag used by the world during the update loop to stop the body from
* receiving positional updates from hierarchies */
@property(nonatomic) BOOL inUpdateLoop;

- (id)initWithB2Body:(b2Body *)body;

- (void)addFixture:(B2DFixture *)fixture;

- (void)removeFixture:(B2DFixture *)fixture;

- (void)updateHost;

- (void)updateBody;

- (id)copyWithZone:(NSZone *)zone;

+ (id)bodyWithB2Body:(b2Body *)body;

+ (id)bodyFromB2Body:(b2Body *)body;

- (NSSet *)allFixtures;
@end


