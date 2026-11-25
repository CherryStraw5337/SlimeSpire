-- 1. Import the module to be tested. Adjust the path according to your project structure.
-- Busted asumes it's in the same directory or in the package path.
local CombatMath = require("systems.combat_math") 

-- 2. 'describe' groups related tests together. The first argument is a string describing what is being tested.
describe("Math Combat System", function()

    describe("Elemental Type Multipliers", function()
        
        -- 3. 'it' defines a single test case. The first argument is a string describing the expected behavior.
        it("should deal double damage (x2) if the attacker exploits a weakness", function()
            -- Fire is strong against Ice.
            local res_dam = CombatMath.calculate_damage("fire", "ice", 10)
            
            assert.are.equal(20, res_dam)
        end)

        it("should deal zero damage (x0) if the defender resists", function()
            -- Ice resists Grass.
            local res_dam = CombatMath.calculate_damage("grass", "ice", 10)
            
            assert.are.equal(0, res_dam)
        end)

        it("should deal normal damage (x1) if they are neutral elements", function()
            -- Elements with no relationship should deal normal damage. For example, Fire vs Earth.
            local res_dam = CombatMath.calculate_damage("fire", "earth", 10)
            
            assert.are.equal(10, res_dam)
        end)

    end)

    -- You can create more blocks to test other things, like critical hits
    describe("Critical Hit Damage Calculation", function()
        
        it("should multiply the final damage by 1.5 on a critical hit", function()
            local is_crit = true
            local res_dam = CombatMath.calculate_damage("earth", "fire", 10, is_crit)
            
            assert.are.equal(15, res_dam)
        end)

    end)

end)