-- "Hello World!" -> "hello_world"
function string.DirtyName(name)
    if istable(name) then
        debug.Trace()
        PrintTable(name)
    end
    return string.lower(name):gsub("[^a-z0-9]+", "_"):gsub("^_+", ""):gsub("_+$", "")
end

function net.WriteCompressedTable(tbl)
    local t = util.TableToJSON(tbl)
    local a = util.Compress(t)
    net.WriteInt(#a,17)
    net.WriteData(a,#a)
end

function net.ReadCompressedTable()
    local textLength = net.ReadInt(17)
    local data = net.ReadData(textLength)
    local jsonText = util.Decompress(data)
    local myTable = util.JSONToTable(jsonText)
    return myTable
end