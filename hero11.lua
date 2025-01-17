local lp, table, tostring, ipairs = love.physics, table, tostring, ipairs

---LuaJIT optimized table unpack
---@overload fun(t: table): ...: unknown
local function unpack(t)
    return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8],
        t[9], t[10], t[11], t[12], t[13], t[14], t[15], t[16]
end

---@generic T love.Joint|love.Body|love.Fixture
---@param t? T[]
---@return T[] t
local function removeDestroyed(t)
    if not t then return {} end
    for i = #t, 1, -1 do
        if t[i]:isDestroyed() then
            table.remove(t, i)
        end
    end
    return t
end

-- Shape
---@class hero11.ShapeState
---@field radius number
---@field type love.ShapeType

local function ChainShape(t)
    local shape = lp.newChainShape(t.loop, t.points)
    shape:setNextVertex(t.nextVertex[1], t.nextVertex[2])
    shape:setPreviousVertex(t.previousVertex[1], t.previousVertex[2])
    return shape
end

local function CircleShape(t)
    return lp.newCircleShape(t.point[1], t.point[2], t.radius)
end

local function EdgeShape(t)
    return lp.newEdgeShape(t.points[1], t.points[2], t.points[3], t.points[4])
end

local function PolygonShape(t)
    return lp.newPolygonShape(t.points)
end

---@type table<love.ShapeType, fun(t: hero11.ShapeState, body: love.Body): love.Shape>
local shapeByType = {
    chain = ChainShape,
    circle = CircleShape,
    edge = EdgeShape,
    polygon = PolygonShape,
}

---@param t hero11.ShapeState
---@param body love.Body
---@return love.Shape
local function Shape(t, body)
    local shape = shapeByType[t.type](t, body)

    t.shape = shape

    return shape
end

local function ChainShapeState(shape)
    return {
        loop = false,
        points = { shape:getPoints() },
        nextVertex = { shape:getNextVertex() },
        previousVertex = { shape:getPreviousVertex() },
    }
end

local function CircleShapeState(shape)
    return {
        point = { shape:getPoint() },
    }
end

local function EdgeShapeState(shape)
    return {
        points = { shape:getPoints() },
    }
end

local function PolygonShapeState(shape)
    return {
        points = { shape:getPoints() },
    }
end

---@type table<love.ShapeType, fun(shape: love.Shape): hero11.ShapeState>
local shapeStateByType = {
    chain = ChainShapeState,
    circle = CircleShapeState,
    edge = EdgeShapeState,
    polygon = PolygonShapeState,
}

---@param shape love.Shape
---@return hero11.ShapeState
local function ShapeState(shape)
    local shapeType = shape:getType()
    local t = shapeStateByType[shapeType](shape)

    t.radius = shape:getRadius()
    t.type = shapeType

    return t
end

-- Fixture
---@class hero11.FixtureState
---@field id string
---@field category number[]
---@field density number
---@field filterData number[]
---@field friction number
---@field groupIndex number
---@field mask number[]
---@field restitution number
---@field sensor boolean
---@field userData any
---@field shapeState hero11.ShapeState

---@field t table|hero11.FixtureState
---@field love.Body
---@return love.Fixture
local function Fixture(t, body)
    local shape = Shape(t.shapeState)
    local fixture = lp.newFixture(body, shape)

    fixture:setCategory(unpack(t.category)) -- up to 16 categories
    fixture:setDensity(t.density)
    fixture:setFilterData(t.filterData[1], t.filterData[2], t.filterData[3])
    fixture:setFriction(t.friction)
    fixture:setGroupIndex(t.groupIndex)
    fixture:setMask(t.mask[1], t.mask[2])
    fixture:setRestitution(t.restitution)
    fixture:setSensor(t.sensor)
    fixture:setUserData(t.userData)

    body:resetMassData()

    t.fixture = fixture

    return fixture
end

---@param fixture love.Fixture
---@return hero11.FixtureState
local function FixtureState(fixture)
    return {
        id = tostring(fixture),
        category = { fixture:getCategory() },
        density = fixture:getDensity(),
        filterData = { fixture:getFilterData() }, -- categories, mask, group
        friction = fixture:getFriction(),
        groupIndex = fixture:getGroupIndex(),
        mask = { fixture:getMask() },
        restitution = fixture:getRestitution(),
        sensor = fixture:isSensor(),
        userData = fixture:getUserData(),

        shapeState = ShapeState(fixture:getShape()),
    }
end

-- Body
---@class hero11.BodyState
---@field id string
---@field active boolean
---@field angle number
---@field angularDamping number
---@field angularVelocity number
---@field awake boolean
---@field bullet boolean
---@field fixedRotation boolean
---@field gravityScale number
---@field inertia number
---@field linearDamping number
---@field linearVelocity number[]
---@field mass number
---@field massData number[]
---@field sleepingAllowed boolean
---@field type love.BodyType
---@field userData any
---@field x number
---@field y number
---@field fixtureStates hero11.FixtureState[]

---@field t table|hero11.BodyState
---@field world love.World
---@return love.Body
local function Body(t, world)
    local body = lp.newBody(world, t.x, t.y, t.type)

    body:setActive(t.active)
    body:setAngle(t.angle)
    body:setAngularDamping(t.angularDamping)
    body:setAngularVelocity(t.angularVelocity)
    body:setAwake(t.awake)
    body:setBullet(t.bullet)
    body:setFixedRotation(t.fixedRotation)
    body:setGravityScale(t.gravityScale)
    body:setInertia(t.inertia)
    body:setLinearDamping(t.linearDamping)
    body:setLinearVelocity(t.linearVelocity[1], t.linearVelocity[2])
    body:setMass(t.mass)
    body:setMassData(t.massData[1], t.massData[2], t.massData[3], t.massData[4])
    body:setSleepingAllowed(t.sleepingAllowed)
    -- body:setType(t.type)
    body:setUserData(t.userData)
    --body:setX(t.x)
    --body:setY(t.y)

    for i, fixtureState in ipairs(t.fixtureStates) do
        Fixture(fixtureState, body)
    end

    t.body = body

    return body
end

---@param body love.Body
---@return hero11.BodyState
local function BodyState(body)
    local fixtureStates = {}

    ---@type love.Fixture[]
    local fixtures = removeDestroyed(body:getFixtures())

    for i, fixture in ipairs(fixtures) do
        fixtureStates[i] = FixtureState(fixture)
    end

    return {
        id = tostring(body),
        -- members
        active = body:isActive(),
        angle = body:getAngle(),
        angularDamping = body:getAngularDamping(),
        angularVelocity = body:getAngularVelocity(),
        awake = body:isAwake(),
        bullet = body:isBullet(),
        fixedRotation = body:isFixedRotation(),
        gravityScale = body:getGravityScale(),
        inertia = body:getInertia(),
        linearDamping = body:getLinearDamping(),
        linearVelocity = { body:getLinearVelocity() },
        mass = body:getMass(),
        massData = { body:getMassData() }, -- x, y, mass, inertia
        -- position = { body:getPosition() },
        sleepingAllowed = body:isSleepingAllowed(),
        type = body:getType(),
        userData = body:getUserData(),
        x = body:getX(),
        y = body:getY(),
        -- children
        fixtureStates = fixtureStates,
    }
end

-- Joint
---@class hero11.JointState
---@field id string
---@field anchors number[]
---@field bodies hero11.BodyState[]
---@field collideConnected boolean
---@field type love.JointType
---@field userData any

local function DistanceJoint(t, bodyMap, jointMap)
    -- body1, body2, x1, y1, x2, y2, collideConnected
    local joint = lp.newDistanceJoint(
        bodyMap[t.bodies[1]].body, bodyMap[t.bodies[2]].body,
        t.anchors[1], t.anchors[2], t.anchors[3], t.anchors[4],
        t.collideConnected)

    joint:setDampingRatio(t.dampingRatio)
    joint:setFrequency(t.frequency)
    joint:setLength(t.length)

    return joint
end

local function FrictionJoint(t, bodyMap, jointMap)
    -- body1, body2, x1, y1, x2, y2, collideConnected
    local joint = lp.newFrictionJoint(
        bodyMap[t.bodies[1]].body, bodyMap[t.bodies[2]].body,
        t.anchors[1], t.anchors[2], t.anchors[3], t.anchors[4],
        t.collideConnected)

    joint:setMaxForce(t.maxForce)
    joint:setMaxTorque(t.maxTorque)

    return joint
end

local function GearJoint(t, bodyMap, jointMap)
    -- joint1, joint2, ratio, collideConnected
    local joint = lp.newGearJoint(
        jointMap[t.joints[1]], jointMap[t.joints[2]],
        t.ratio,
        t.collideConnected)
    return joint
end

local function MotorJoint(t, bodyMap, jointMap)
    -- body1, body2, correctionFactor, collideConnected
    local joint = lp.newMotorJoint(
        bodyMap[t.bodies[1]].body, bodyMap[t.bodies[2]].body,
        t.correctionFactor,
        t.collideConnected)

    joint:setAngularOffset(t.angularOffset)
    joint:setLinearOffset(t.linearOffset[1], t.linearOffset[2])
    -- joint:setMaxForce(t.maxForce)
    -- joint:setMaxTorque(t.maxTorque)

    return joint
end

local function MouseJoint(t, bodyMap, jointMap)
    -- body, x, y
    local joint = lp.newMouseJoint(
        bodyMap[t.bodies[1]].body,
        t.target[1], t.target[2])

    joint:setDampingRatio(t.dampingRatio)
    joint:setFrequency(t.frequency)
    joint:setMaxForce(t.maxForce)

    return joint
end

local function PrismaticJoint(t, bodyMap, jointMap)
    -- body1, body2, x1, y1, x2, y2, ax, ay, collideConnected, referenceAngle
    local joint = lp.newPrismaticJoint(
        bodyMap[t.bodies[1]].body, bodyMap[t.bodies[2]].body,
        t.anchors[1], t.anchors[2], t.anchors[3], t.anchors[4],
        t.axis[1], t.axis[2],
        t.collideConnected, t.referenceAngle)

    joint:setLowerLimit(t.lowerLimit)
    joint:setMaxMotorForce(t.maxMotorForce)
    joint:setMotorEnabled(t.motorEnabled)
    joint:setMotorSpeed(t.motorSpeed)
    joint:setUpperLimit(t.upperLimit)
    joint:setLimitsEnabled(t.limitsEnabled)

    return joint
end

local function PulleyJoint(t, bodyMap, jointMap)
    -- body1, body2, gx1, gy1, gx2, gy2, x1, y1, x2, y2, ratio, collideConnected
    local joint = lp.newPulleyJoint(
        bodyMap[t.bodies[1]].body, bodyMap[t.bodies[2]].body,
        t.groundAnchors[1], t.groundAnchors[2],
        t.groundAnchors[3], t.groundAnchors[4],
        t.anchors[1], t.anchors[2], t.anchors[3], t.anchors[4],
        t.ratio,
        t.collideConnected)

    return joint
end

local function RevoluteJoint(t, bodyMap, jointMap)
    -- body1, body2, x1, y1, x2, y2, collideConnected, referenceAngle
    local joint = lp.newRevoluteJoint(
        bodyMap[t.bodies[1]].body, bodyMap[t.bodies[2]].body,
        t.anchors[1], t.anchors[2], t.anchors[3], t.anchors[4],
        t.collideConnected, t.referenceAngle)

    joint:setLowerLimit(t.lowerLimit)
    joint:setMaxMotorTorque(t.maxMotorTorque)
    joint:setMotorEnabled(t.motorEnabled)
    joint:setMotorSpeed(t.motorSpeed)
    joint:setUpperLimit(t.upperLimit)
    joint:setLimitsEnabled(t.limitsEnabled)

    return joint
end

local function RopeJoint(t, bodyMap, jointMap)
    -- body1, body2, x1, y1, x2, y2, maxLength, collideConnected
    local joint = lp.newRopeJoint(
        bodyMap[t.bodies[1]].body, bodyMap[t.bodies[2]].body,
        t.anchors[1], t.anchors[2], t.anchors[3], t.anchors[4],
        t.maxLength,
        t.collideConnected)

    return joint
end

local function WeldJoint(t, bodyMap, jointMap)
    -- body1, body2, x1, y1, x2, y2, collideConnected, referenceAngle
    local joint = lp.newWeldJoint(
        bodyMap[t.bodies[1]].body, bodyMap[t.bodies[2]].body,
        t.anchors[1], t.anchors[2], t.anchors[3], t.anchors[4],
        t.collideConnected, t.referenceAngle)

    joint:setDampingRatio(t.dampingRatio)
    joint:setFrequency(t.frequency)

    return joint
end

local function WheelJoint(t, bodyMap, jointMap)
    -- body1, body2, x1, y1, x2, y2, ax, ay, collideConnected
    local joint = lp.newWheelJoint(
        bodyMap[t.bodies[1]].body, bodyMap[t.bodies[2]].body,
        t.anchors[1], t.anchors[2], t.anchors[3], t.anchors[4],
        t.axis[1], t.axis[2],
        t.collideConnected)

    joint:setMaxMotorTorque(t.maxMotorTorque)
    joint:setMotorEnabled(t.motorEnabled)
    joint:setMotorSpeed(t.motorSpeed)
    joint:setSpringDampingRatio(t.springDampingRatio)
    joint:setSpringFrequency(t.springFrequency)

    return joint
end

---@type table<love.JointType, fun(t: table|hero11.JointState, bodyMap: bodyMap table<love.Body, string>, jointMap: table<love.Joint, string>): love.Joint>
local jointByType = {
    distance = DistanceJoint,
    friction = FrictionJoint,
    gear = GearJoint,
    motor = MotorJoint,
    mouse = MouseJoint,
    prismatic = PrismaticJoint,
    pulley = PulleyJoint,
    revolute = RevoluteJoint,
    rope = RopeJoint,
    weld = WeldJoint,
    wheel = WheelJoint,
}

---@param t table|hero11.JointState
---@param bodyMap table<love.Body, string>
---@param jointMap table<love.Joint, string>
---@return love.Joint
local function Joint(t, bodyMap, jointMap)
    local joint = jointByType[t.type](t, bodyMap, jointMap)

    joint:setUserData(t.userData)

    t.joint = joint

    return joint
end

-- create joint states by joint type

local function DistanceJointState(joint, bodyMap, jointMap)
    return {
        dampingRatio = joint:getDampingRatio(),
        frequency = joint:getFrequency(),
        length = joint:getLength(),
    }
end

local function FrictionJointState(joint, bodyMap, jointMap)
    return {
        maxForce = joint:getMaxForce(),
        maxTorque = joint:getMaxTorque(),
    }
end

local function GearJointState(joint, bodyMap, jointMap)
    local jointA, jointB = joint:getJoints()
    return {
        joints = { jointMap[jointA], jointMap[jointB] },
        ratio = joint:getRatio(),
    }
end

local function MotorJointState(joint, bodyMap, jointMap)
    return {
        angularOffset = joint:getAngularOffset(),
        linearOffset = { joint:getLinearOffset() },
        -- maxForce = joint:getMaxForce(),
        -- maxTorque = joint:getMaxTorque(),
        -- correctionFactor = joint:getCorrectionFactor(),
    }
end

local function MouseJointState(joint, bodyMap, jointMap)
    return {
        dampingRatio = joint:getDampingRatio(),
        frequency = joint:getFrequency(),
        maxForce = joint:getMaxForce(),
        target = { joint:getTarget() },
    }
end

local function PrismaticJointState(joint, bodyMap, jointMap)
    return {
        axis = { joint:getAxis() },
        lowerLimit = joint:getLowerLimit(),
        maxMotorForce = joint:getMaxMotorForce(),
        motorSpeed = joint:getMotorSpeed(),
        upperLimit = joint:getUpperLimit(),
        limitsEnabled = joint:areLimitsEnabled(),
        motorEnabled = joint:isMotorEnabled(),
        referenceAngle = joint:getReferenceAngle(),
    }
end

local function PulleyJointState(joint, bodyMap, jointMap)
    return {
        groundAnchors = { joint:getGroundAnchors() },
        ratio = joint:getRatio(),
    }
end

local function RevoluteJointState(joint, bodyMap, jointMap)
    return {
        lowerLimit = joint:getLowerLimit(),
        maxMotorTorque = joint:getMaxMotorTorque(),
        motorSpeed = joint:getMotorSpeed(),
        upperLimit = joint:getUpperLimit(),
        limitsEnabled = joint:hasLimitsEnabled(),
        motorEnabled = joint:isMotorEnabled(),
        referenceAngle = joint:getReferenceAngle(),
    }
end

local function RopeJointState(joint, bodyMap, jointMap)
    return {
        maxLength = joint:getMaxLength(),
    }
end

local function WeldJointState(joint, bodyMap, jointMap)
    return {
        dampingRatio = joint:getDampingRatio(),
        frequency = joint:getFrequency(),
        referenceAngle = joint:getReferenceAngle(),
    }
end

local function WheelJointState(joint, bodyMap, jointMap)
    return {
        axis = { joint:getAxis() },
        maxMotorTorque = joint:getMaxMotorTorque(),
        motorSpeed = joint:getMotorSpeed(),
        springDampingRatio = joint:getSpringDampingRatio(),
        springFrequency = joint:getSpringFrequency(),
        motorEnabled = joint:isMotorEnabled(),
    }
end

---@type table<love.JointType, fun(joint: love.Joint, bodyMap: table<love.Body, string>, jointMap: table<love.Joint, string>): hero11.JointState>
local jointStateByType = {
    distance = DistanceJointState,
    friction = FrictionJointState,
    gear = GearJointState,
    motor = MotorJointState,
    mouse = MouseJointState,
    prismatic = PrismaticJointState,
    pulley = PulleyJointState,
    revolute = RevoluteJointState,
    rope = RopeJointState,
    weld = WeldJointState,
    wheel = WheelJointState,
}

---@param joint love.Joint
---@param bodyMap table<love.Body, string>
---@param jointMap table<love.Joint, string>
---@return hero11.JointState
local function JointState(joint, bodyMap, jointMap)
    local t = jointStateByType[joint:getType()](joint, bodyMap, jointMap)

    if bodyMap then
        local bodyA, bodyB = joint:getBodies()
        t.bodies = { bodyMap[bodyA], bodyMap[bodyB] }
    end

    t.anchors = { joint:getAnchors() }
    t.collideConnected = joint:getCollideConnected()
    t.type = joint:getType()
    t.userData = joint:getUserData()
    t.id = tostring(joint)

    return t
end

-- World
---@class hero11.WorldState
---@field gravity number[]
---@field sleepingAllowed boolean
---@field bodyStates hero11.BodyState[]
---@field jointStates hero11.JointState[]

---Load a saved world.
---@param t table|hero11.WorldState
---@param world? love.World
---@return love.World
---@return table<string, love.Joint|love.Body|love.Fixture>
local function World(t, world)
    ---@type table<string, love.Joint|love.Body|love.Fixture>
    local lookup = {}
    local bodyMap, jointMap = {}, {}

    world = world or lp.newWorld()
    world:setGravity(t.gravity[1], t.gravity[2])
    world:setSleepingAllowed(t.sleepingAllowed)

    -- index all bodies and add them to the world
    for i, bodyState in ipairs(t.bodyStates) do
        bodyMap[i] = bodyState
        lookup[bodyState.id] = Body(bodyState, world)
        for _, fixtureState in ipairs(bodyState.fixtureStates) do
            lookup[fixtureState.id] = fixtureState.fixture
        end
    end

    -- first pass over joints; index them all
    for i, jointState in ipairs(t.jointStates) do
        jointMap[i] = jointState
    end

    -- second pass over joints; add them to the world
    for i, jointState in ipairs(t.jointStates) do
        lookup[jointState.id] = Joint(jointState, bodyMap, jointMap)
    end

    return world, lookup
end

local function sortGears(a, b)
    return (a:getType() ~= 'gear' and b:getType() == 'gear')
        or tostring(a) < tostring(b)
end

---Save the world's state to a serializable table.
---@param world love.World
---@return hero11.WorldState
local function WorldState(world)
    ---@type love.Body[]
    local bodies = removeDestroyed(world:getBodies())
    ---@type love.Joint[]
    local joints = removeDestroyed(world:getJoints())
    local bodyStates, bodyMap, jointStates, jointMap = {}, {}, {}, {}

    for i, body in ipairs(bodies) do
        bodyMap[body] = i
        bodyStates[i] = BodyState(body)
    end

    table.sort(joints, sortGears)

    for i, joint in ipairs(joints) do
        jointMap[joint] = i
    end

    for i, joint in ipairs(joints) do
        jointStates[i] = JointState(joint, bodyMap, jointMap)
    end

    return {
        -- members
        gravity = { world:getGravity() },
        sleepingAllowed = world:isSleepingAllowed(),
        -- children
        bodyStates = bodyStates,
        jointStates = jointStates,
    }
end

---@class hero11
return {
    Body = Body,
    BodyState = BodyState,
    Fixture = Fixture,
    FixtureState = FixtureState,
    Joint = Joint,
    JointState = JointState,
    World = World,
    WorldState = WorldState,
    load = World,
    save = WorldState,
}
