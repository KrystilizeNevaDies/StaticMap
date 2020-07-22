



function Initialize(Plugin)
	Plugin:SetName("StaticMap")
	Plugin:SetVersion(1)
	
    
    
    GlobalTick = 0
	Chunks = {}
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
    if OS = "Linux" then
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
	BinaryFormat = nil
	
    LOG("Detected Operating System: " .. OS)
    if OS == "Linux" then
        LOG("Detected Arch: " .. ARCH)
    end
	
	
    
    
    
	cPluginManager:AddHook(cPluginManager.HOOK_CHUNK_GENERATED, OnChunkGenerated);
    cPluginManager:AddHook(cPluginManager.HOOK_TICK, OnTick);
	cPluginManager:AddHook(cPluginManager.HOOK_WORLD_STARTED, OnWorldStarted);
    
    
	
	LOGINFO(" - Static Map Loaded - ")
	
	
	
	
	
	return true
end




function OnChunkGenerated(World, ChunkX, ChunkZ, ChunkDesc)
    local FileName = "Chunk" .. ChunkX .. "." .. ChunkZ .. ".png"
    if not(cFile:IsFile("..\\..\\webadmin\\files\\images" .. Sep .. FileName)) then
        local BlockMap = {}
        for x = 1, 16 do
            BlockMap[x] = {}
            for y = 1, 16 do
                BlockMap[x][y] = tonumber(ChunkDesc:GetBlockType(x, ChunkDesc:GetHeight(x, y), y))
            end
        end
        table.insert(Chunks, {FileName, BlockMap})
    end
end







function GenerateChunkImage(FileName, BlockMap)
    local Temp = ""
    local lines = {}
    local line = {}
    local out = {}
    for x = 1, 16 do
        for y = 1, 16 do
            local color = "000 000 000 "
            for Key = 1, #ColorTable do
                if ColorTable[Key][1] == BlockMap[x][y] then
                    color = ColorTable[Key][2]
                end
            end
            Temp = Temp .. color
            
            
            if y % 4 == 0 then
                table.insert(lines, Temp)
                Temp = "\n"
            end
            
            
        end
        out[x] = table.concat(lines)
        lines = {}
        
    end
    local Blocks = table.concat(out, '\n')
    
    cFile:CreateFolder(Directory .. ".." .. Sep .. ".." .. Sep .. "webadmin/files/images")
    cFile:CreateFolder(Directory .. "Images" .. Sep)
	local Image = io.open(Directory .. "Images" .. Sep .. "img.ppm", "w")
	Image:write("P3\n" .. 16 .. " " .. 16 .. "\n255\n" .. Blocks)
	Image:close()
    
    
    
    if OS == "Windows" then
        for Key, Value in pairs(Chunks) do
            if Value[1] == FileName then
                Command = Directory .. "Magik\\Windows\\convert " .. Directory .. "Images\\img.ppm " .. Directory .. "..\\..\\webadmin\\files\\images" .. Sep .. FileName .. ".png \n"
            end
        end
        os.execute(Command)
    elseif OS == "Linux" then
        for Key, Value in pairs(Chunks) do
            if Value[1] == FileName then
                if ARCH == "x86_64" then
                    Command = Directory .. "Magik\\linuxmagick convert " .. Directory .. "Images\\img.ppm " .. Directory .. "..\\..\\webadmin\\files\\images" .. Sep .. FileName .. ".png \n"
                elseif ARCH == "aarch64" then
                    Command = Directory .. "Magik\\linuxmagick_aarch64 convert " .. Directory .. "Images\\img.ppm " .. Directory .. "..\\..\\webadmin\\files\\images" .. Sep .. FileName .. ".png \n"
                end
            end
        end
        os.execute(Command)
    end
    
    
    
end



function OnTick(Delta)
    if GlobalTick % 1 == 0 then
        if #Chunks > 0.5 then
            local Temp = 0
            for Key, Value in pairs(Chunks) do
                if Temp < 0.5 then
                    GenerateChunkImage(Chunks[Key][1], Chunks[Key][2])
                    Temp = Temp + 1
                    Chunks[Key] = nil
                end
            end
        end
    end
    GlobalTick = GlobalTick + 1
    
end


function OnWorldStarted(World)
    for Key, Value in pairs(Chunks) do
        GenerateChunkImage(Chunks[Key][1], Chunks[Key][2])
        Chunks[Key] = nil
    end
end




