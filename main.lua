



function Initialize(Plugin)
	Plugin:SetName("StaticMap")
	Plugin:SetVersion(1)
	
	
    ChunkResolution = 128
    ColorTable = InitialiseColorTable()
	Sep = cFile:GetPathSeparator()
	Directory = "Plugins" .. Sep .. Plugin:GetFolderName() .. Sep
	
	
    
    
	LOGINFO(" - Static Map Loading - ")
	
	
	
	
	
	local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
	
	if BinaryFormat == "dll" then
		OS = "Windows"
	elseif BinaryFormat == "so" then
		OS = "Linux"
	elseif BinaryFormat == "dylib" then
		OS = "MacOS"
	end
	
	BinaryFormat = nil
	
	LOG("Detected Operating System: " .. OS)
	
	
    
    
    
	cPluginManager:AddHook(cPluginManager.HOOK_CHUNK_GENERATED, OnChunkGenerated);

	
    
    
	
	LOGINFO(" - Static Map Loaded - ")
	
	
	
	
	
	return true
end




function OnChunkGenerated(World, ChunkX, ChunkZ, ChunkDesc)
    local FileName = "Chunk" .. ChunkX .. "." .. ChunkZ .. ".png"
    if not(cFile:IsFile("..\\..\\webadmin\\files\\images" .. Sep .. FileName)) then
        RenderChunk(World, ChunkX, ChunkZ, ChunkDesc)
    end
end







function RenderChunk(World, ChunkX, ChunkZ, ChunkDesc)
    LOG("Rendering Chunk: " .. ChunkX .. "|" .. ChunkZ)
    local Percentage = 0
	local Temp = ""
	local lines = {}
	local line = {}
	local out = {}
	for x = 1, 16 do
		for y = 1, 16 do
			local color
            for Key, Value in pairs(ColorTable) do
                if Value[1] == ChunkDesc:GetBlockType(x, ChunkDesc:GetHeight(x, y), y) then
                    color = Value[2]
                end
            end
            
			Temp = Temp .. color
			
			
			if y % 4 == 0 then
				table.insert(lines, Temp)
				Temp = "\n"
			elseif y == Resolution then
                table.insert(lines, Temp)
            end
			
			
		end
		out[x] = table.concat(lines)
		for K,V in pairs(lines) do
			lines[K] = nil
		end
		
	end
    local Blocks = table.concat(out, '\n')
    
    cFile:CreateFolder(Directory .. ".." .. Sep .. ".." .. Sep .. "webadmin/files/images")
	local Image = io.open (Directory .. "Images" .. Sep .. "img.ppm", "w+")
	Image:write("P3\n" .. 16 .. " " .. 16 .. "\n255\n")
	Image:write(Blocks)
	Image:close()
    local FileName = "Chunk" .. ChunkX .. "." .. ChunkZ .. ".png"
    if OS == "Windows" then
        local Command = Directory .. "Magik\\Windows\\convert " .. Directory .. "Images\\img.ppm " .. Directory .. "..\\..\\webadmin\\files\\images" .. Sep .. FileName
        os.execute(Command)
    end
end



