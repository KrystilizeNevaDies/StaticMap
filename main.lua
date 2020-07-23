



function Initialize(Plugin)
	Plugin:SetName("StaticMap")
	Plugin:SetVersion(1)
	
  
  
  
  
	-- Initialize GlobalVars
	ChunksPerRender = 1
	TicksPerRender = 20
	GlobalTick = 0
	Chunks = {}
	ColorTable = InitialiseColorTable()
	Sep = cFile:GetPathSeparator()
	Directory = "Plugins" .. Sep .. Plugin:GetFolderName() .. Sep
	
	
  
  
	LOGINFO(" - Static Map Loading - ")
	
	
	
	
	
	-- Find the specific operating system
	local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
	
	if BinaryFormat == "dll" then
			OS = "Windows"
	elseif BinaryFormat == "so" then
		OS = "Linux"
	elseif BinaryFormat == "dylib" then
		OS = "MacOS"
	end
    if OS == "Linux" then -- Find linux Architecture
        n = os.tmpname()

        os.execute("uname -a > " .. n)

        for line in io.lines(n) do
            if string.match(line, "x86_64") then
                ARCH = "x86_64"
            elseif string.match(line, "aarch64") then
                ARCH = "aarch64"
            end
        end

        os.remove(n)
    end
	BinaryFormat = nil

    LOG("Detected Operating System: " .. OS)
    if OS == "Linux" then
        LOG("Detected Arch: " .. ARCH)
    end




	-- Initialise Hooks
	cPluginManager:AddHook(cPluginManager.HOOK_CHUNK_GENERATED, OnChunkGenerated);
    cPluginManager:AddHook(cPluginManager.HOOK_TICK, OnTick);
	cPluginManager:AddHook(cPluginManager.HOOK_WORLD_STARTED, OnWorldStarted);



	LOGINFO(" - Static Map Loaded - ")





	return true
end




function OnChunkGenerated(World, ChunkX, ChunkZ, ChunkDesc)
  --[[
  The chunk generated event is where heightmaps are generated and scheduled to be processed.
  
  
  ]]
      local FileName = "Chunk" .. ChunkX .. "." .. ChunkZ
      
      if not(cFile:IsFile("..\\..\\webadmin\\files\\images" .. Sep .. FileName)) then -- If file doesn't exist, start generating heightmap
          local BlockMap = {}
          for x = 1, 16 do
              BlockMap[x] = {}
              for y = 1, 16 do
                  BlockMap[x][y] = tonumber(ChunkDesc:GetBlockType(x, ChunkDesc:GetHeight(x, y), y))
              end
          end
          table.insert(Chunks, {FileName, BlockMap}) -- Schedule Heightmap to be processed
      end
end







function GenerateChunkImage(FileName, BlockMap)
  --[[
  This function first processes heightmaps into their colored ppm files
  
  Then it uses image magick to convert the ppm file into a png and place it jnto the correct directory
  ]]

    -- Start Heightmap Processing
    local Temp = ""
    local lines = {}
    local line = {}
    local out = {}
    
    
    
    
    -- Iterate over every value and assign a color to the ppm file
    for x = 1, 16 do
        for y = 1, 16 do
            local color = "000 000 000 "
            for Key = 1, #ColorTable do -- Find and assign color
                if ColorTable[Key][1] == BlockMap[x][y] then
                    color = ColorTable[Key][2]
                end
            end
            
            
            
            
            
            Temp = Temp .. color -- Add color to file
            
            
            
            
            
            if y % 4 == 0 then -- Add a line break every 4 color values
                table.insert(lines, Temp)
                Temp = "\n"
            end
        end
        
        
        
        
        
        out[x] = table.concat(lines, "")
        lines = {}
    end
    local Blocks = table.concat(out, '\n') -- Compile ppm file
    
    
    
    
    -- Ensure folders exist
    cFile:CreateFolder(Directory .. ".." .. Sep .. ".." .. Sep .. "webadmin/files/images")
    cFile:CreateFolder(Directory .. "Images" .. Sep)
    
    
    
    
      -- Write PPM metadata + RGB Values
    local Image = io.open(Directory .. "Images" .. Sep .. "img.ppm", "w")
    Image:write("P3\n" .. 16 .. " " .. 16 .. "\n255\n" .. Blocks)
    Image:close()

    
    
    local Command = ""
    
    
    
    
    if OS == "Windows" then
        for Key, Value in pairs(Chunks) do -- Get Windows Command
            if Value[1] == FileName then
                Command = Directory .. "Magick\\Windows\\convert " .. Directory .. "Images\\img.ppm " .. Directory .. "..\\..\\webadmin\\files\\images" .. Sep .. FileName .. ".png \n"
            end
        end
    elseif OS == "Linux" then
        for Key, Value in pairs(Chunks) do -- Get Linux Command
            if Value[1] == FileName then
                if ARCH == "x86_64" then
                    Command = Directory .. "Magick/linuxmagick convert " .. Directory .. "Images/img.ppm " .. Directory .. "../../webadmin/files/images" .. Sep .. FileName .. ".png \n"
                elseif ARCH == "aarch64" then
                    Command = Directory .. "Magick/linuxmagick_aarch64 convert " .. Directory .. "Images/img.ppm " .. Directory .. "../../webadmin/files/images" .. Sep .. FileName .. ".png \n"
                end
            end
        end
    end
    -- TODO: MacOS
    
    
    
    
    
    os.execute(Command)
end





function OnTick(Delta)
    if GlobalTick % TicksPerRender == 0 then -- If A render is currently allowed
        if #Chunks > 0.5 then -- If more then one render is scheduled
            local Temp = 0
            for Key, Value in pairs(Chunks) do -- Renders Per Tick Chunks
                if Temp < ChunksPerRender then
                    GenerateChunkImage(Chunks[Key][1], Chunks[Key][2])
                    Temp = Temp + 1
                    Chunks[Key] = nil
                end
            end
        end
    end
    GlobalTick = GlobalTick + 1
end


function OnWorldStarted(World) -- Render all generated chunks on startup
	if #Chunks > 10 then
		LOG("Please Wait - Rendering Startup Chunks")
		for Key, Value in pairs(Chunks) do
			GenerateChunkImage(Chunks[Key][1], Chunks[Key][2])
			Chunks[Key] = nil
		end
		LOG("Finished")
	end
end




