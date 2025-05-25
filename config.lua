--[[
  ================================
      MAIN CONFIGURATION TABLE
  ================================
]]
Config = Config or {}

--[[
  --------------------------------
     ADMIN PERMISSIONS & COMMANDS
  --------------------------------
]]
-- Which groups have “star admin” privileges
Config.StarAdminGroups = {
    admin      = true,
    superadmin = true,
}

-- Shortcuts for core commands
Config.StarCommands = {
    add         = 'addstars',     -- Add points
    remove      = 'removestars',  -- Remove points
    check       = 'checkstars',   -- Check points
    resetplates = 'resetplates',  -- Reset custom plates
}

--[[
  -------------------------------
       ORGANIZATIONS SETTINGS
  -------------------------------
]]
Config.Organizations = {
    vagos = {
        label     = "Vagos",                   -- Display name
        society   = "society_vagos",           -- Database identifier
        color     = { r = 255, g = 215, b = 0},-- Organization RGB color
        blipColor = 5,                         -- Blip color ID

        -- Key locations (boss menu, safe, garage, vehicle spawn)
        locations = {
            boss     = vec4(-371.3696, -137.9741, 38.6852, 116.0),
            safe     = vec4(-366.9893, -138.8256, 38.0945, 211.0684),
            garage   = vec4(-377.0645, -132.8397, 38.6860, 315.6017),
            vehspawn = vec4(-365.4262, -126.7204, 38.6957,  69.1225),
        },

        -- Prop models (safe, laptop, parking meter)
        safeprop   = "prop_ld_int_safe_01",
        bossprop   = "prop_laptop_01a",
        garageprop = "prop_parkingpay",

        -- Organization vehicle fleet (label, model, required grade)
        vehicles = {
            { label = "Rebla GTS",    model = "rebla",    grade = 0 },
            { label = "Schafter V12", model = "schafter3", grade = 1 },
            { label = "LM-87",        model = "lm87",     grade = 2 },
        },
    },

    ballas = {
        label     = "Ballas",
        society   = "society_ballas",
        color     = { r = 255, g = 0, b = 0 },
        blipColor = 1,

        locations = {
            boss     = vec4(-360.3460, -122.4706, 38.6961 - 1,   332.3335),
            safe     = vec4(-364.6680, -119.7544, 38.6961 - 0.5,  61.9858),
            garage   = vec4(-370.8538, -120.3754, 38.6811 - 1,   165.0601),
            vehspawn = vec4(-365.4262, -126.7204, 38.6957,       69.1225),
        },

        safeprop   = "prop_ld_int_safe_01",
        bossprop   = "prop_laptop_01a",
        garageprop = "prop_parkingpay",

        vehicles = {
            { label = "Rebla GTS",     model = "rebla",    grade = 0 },
            { label = "Schafter V12",  model = "schafter3", grade = 1 },
            { label = "Sanchez",       model = "sanchez",  grade = 2 },
        },
    },
}

--[[
  -------------------------------
          UPGRADE SYSTEM
  -------------------------------
]]
Config.Upgrades = {
    {
        key         = "vehicle_mods",           -- Internal key
        label       = "Vehicle Modifications", -- Display label
        description = "Tune organization vehicles using STAR points",
        cost        = 200,                      -- Cost per level
        maxLevel    = 5,                        -- Maximum upgrade level
    },
    {
        key         = "safe_weight",
        label       = "Increased Safe Capacity",
        description = "Adds +50kg capacity to the organization safe",
        cost        = 250,
        maxLevel    = 3,
    },
    {
        key         = "custom_plate",
        label       = "Custom License Plate",
        description = "Set the first three letters of a vehicle’s plate",
        cost        = 500,
        maxLevel    = 1,
    },
}

--[[
  -------------------------------
           SHOP ITEMS
  -------------------------------
]]
Config.ShopItems = {
    {
        label = "Burger",               -- Item display name
        price = 100,                    -- Purchase price
        prop  = 'prop_cs_burger_01',    -- Prop model
        item  = 'testburger',           -- Internal item name
    },
    {
        label = "High Tech Laptop",
        price = 200,
        prop  = 'prop_laptop_lester2',
        item  = 'burger',
    },
}

--[[
  -------------------------------
       VEHICLE & PED SETTINGS
  -------------------------------
]]
Config.VanModel     = 'speedo'                   -- Delivery van model
Config.PedModel     = 'g_m_m_chigoon_01'         -- NPC model

Config.VanLocations = {                           -- Van spawn points
    {
        coords  = vec3(-380.8528, -117.5005, 38.6875),
        heading = 11.9702,
    },
    {
        coords  = vec3(-369.6392, -115.3200, 38.6796),
        heading = 153.4967,
    },
}

Config.PedOffset         = vec3(-1.5, -2.5, -0.7) -- NPC offset from van
Config.PedHeadingOffset  = 194.7278               -- NPC facing direction
Config.PedAnimation = {                            -- NPC idle animation
    dict = 'anim@amb@nightclub@peds@',
    anim = 'amb_world_human_hang_out_street_male_c_base',
}

--[[
  -------------------------------
           MISCELLANEOUS
  -------------------------------
]]
Config.RopeItem = 'ziptie'  -- Item required for tying up


