
--
-- Paraglider mod for repixture
-- By m492
--
--
--
local S = minetest.get_translator("paraglider")
local yaw = 0


local function thermals(posVector, timeOfDay)
   local maxForce = 0.43
   local r = math.sqrt(posVector.x ^ 2 + posVector.z ^ 2)
   local a = math.acos(posVector.x / r)
   local waveProb = (math.sin(r / 50 + timeOfDay * math.pi * 2) + 0.5) + (math.sin(r / 50 * (a + timeOfDay) * math.pi * 2) + 0.5) 
   return maxForce * waveProb
  
end 

minetest.register_craftitem(
   "paraglider:paraglider", {
      description = S("Paraglider"),
      _tt_help = S("Travel with the wind"),
      inventory_image = "paraglider_inventory.png",
      wield_image = "paraglider_inventory.png",
      stack_max = 1,
      on_activate = function(self)
         self.object:set_armor_groups({immortal=1})
      end,
      on_use = function(itemstack, player, pointed_thing)
         local name = player:get_player_name()

         local pos = player:get_pos()

         local on = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})

         if default.player_attached[name] then
            return
         end

         if on.name == "air" then
            -- Spawn paraglider
            pos.y = pos.y + 3

            local ent = minetest.add_entity(pos, "paraglider:entity")

            ent:set_velocity(
               {
                  x = 0,
                  y = math.min(0, player:get_player_velocity().y),
                  z = 0
            })

            player:set_attach(ent, "", {x = 0, y = -8, z = 0}, {x = 0, y = 0, z = 0})

            ent:set_yaw(player:get_look_horizontal())
	    
	    yaw = player:get_look_horizontal()

            ent = ent:get_luaentity()
            ent.attached = name

            default.player_attached[player:get_player_name()] = true

            if not minetest.settings:get_bool("creative_mode") then
                itemstack:take_item()
            end

            return itemstack
         else
            minetest.chat_send_player(
               player:get_player_name(),
               minetest.colorize("#FFFF00", S("You have to jump from hill :)")))
         end
      end
})

minetest.register_entity(
   "paraglider:entity",
   {
      visual = "mesh",
      mesh = "paraglider.b3d",
      textures = {"paraglider_mesh.png"},
      physical = false,
      pointable = false,
      automatic_face_movement_dir = -90,

      attached = nil,
      start_y = nil,

      on_activate = function(self, staticdata, dtime_s)
         if dtime_s == 0 then
           local pos = self.object:get_pos()
           self.start_y = pos.y
	   --yaw = math.pi - player:get_look_horizontal()
         end
      end,
      on_step = function(self, dtime)
         local pos = self.object:get_pos()
         local under = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})

         if self.attached ~= nil then
            local player = minetest.get_player_by_name(self.attached)

            local vel = self.object:get_velocity()

	

            local controls = player:get_player_control()

            local speed = 2.0
	    
	    local downRate = -0.5

	     
	    if controls.up then
	       downRate = -1
	       speed = 4.7
	       
            elseif controls.down then
	       downRate = -0.2
	       speed = 1
	    end
	       
	    if controls.right then
	      
	    
	       yaw = yaw - math.pi / 96
	
            elseif controls.left then
	      
	       yaw = yaw + math.pi / 96
	    
            end
	    
	    self.object:set_yaw(yaw)
	    yawVector = vector.multiply(minetest.yaw_to_dir(yaw), speed)
	    yawVector.y = downRate + thermals(self.object:get_pos(), minetest.get_timeofday())
	    self.object:set_velocity(yawVector)
	   
	    

            if under.name ~= "air" then
               default.player_attached[self.attached] = false
            end
         end

         if under.name ~= "air" then
            if self.attached ~= nil then
               default.player_attached[self.attached] = false

               local player = minetest.get_player_by_name(self.attached)
              
               self.object:set_detach()
            end

            self.object:remove()
         end
      end
})

-- Crafting

crafting.register_craft(
   {
      output = "paraglider:paraglider",
      items = {
         "group:fuzzy 6",
         "default:rope 6",
         "default:stick 8",
      }
})


default.log("mod:paraglider", "loaded")
