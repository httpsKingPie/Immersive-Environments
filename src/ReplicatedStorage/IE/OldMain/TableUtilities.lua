local Utilities = {}

Utilities.Table = {}

local tabela = Utilities.Table

-- TableToPrint: passe como argumento: uma tabela e a pasta que quer
function tabela.TableToFolder(tabela, lugar)
	
	local i = true
	
	for name, obj in pairs(tabela) do

		if type(obj) == "table" then
			
			local pasta = Instance.new("Folder",lugar)
			pasta.Name = name
			Utilities.Table.TableToFolder(obj, pasta)
		else
			if type(obj) == "string" then
				
				if obj == "true" or obj == "false" then
					
					local value = Instance.new("BoolValue", lugar)
					value.Name = name
					if obj == "true" then
						
						value.Value = true
						
					else
						
						value.Value = false
						
					end 
				else
					
					local value = Instance.new("StringValue", lugar)
					value.Name = name	
					value.Value = obj
					
				end
			elseif type(obj == "number") then
				
				local value = Instance.new("IntValue", lugar)
				value.Name = name
				value.Value = obj
				
			end
					
		end
		
	end 
end

-- FolderToTable: passe a pasta a ser transformada em tabela e a função retorna a tabela
function tabela.FolderToTable(folder)

	local temp = {}
	
	local tabela = temp
	
	local children = folder:GetChildren()
	
	for key,obj in pairs(children)do
		
		if obj:IsA("Folder") then
			tabela[obj.Name] = Utilities.Table.FolderToTable(obj)	
			
		elseif obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") then
			
			tabela[obj.Name] = {}
			
			if type(obj.Value) == "string" then
				tabela[obj.Name] = tostring(obj.Value)
			elseif type(obj.Value) == "boolean" then
				tabela[obj.Name] = tostring(obj.Value)
			elseif type(obj.Value) == "number" then
				tabela[obj.Name] = obj.Value
				
			end
			
		end
			
	end
	
	return tabela
end

-- PrintTable: passe a Tabela que quer que seja transformada em texto
function tabela.TableToString(tabela, sub, nivel)
	if sub == nil then 
		sub = false
	end
	if nivel == nil then
		nivel = 0
	end
	
	local espaco = ""
	local espaco1 = ""
	for i=0, nivel, 1 do
		espaco = espaco.."        "
	end
	for i=1, nivel, 1 do
		espaco1 = espaco1.."        "
	end
	local onSubTable = sub
		
	local text = ""
	for keys, values in pairs(tabela) do
		if (type(values) == "table") then
			local chave = tostring(keys)
			text = text..chave..": \n"..espaco.."{"..Utilities.Table.TableToString(values, true, nivel+1).."}\n"..espaco1
		else
			if onSubTable == false then
				local chave = tostring(keys)
				text = text..chave..": "..values.."\n"
			else
				local toValue
				local chave = tostring(keys)
				if (type(values) == "function") then
					toValue = "Function"
				else
					toValue = tostring(values)
				end
				
				text = text..chave..": "..toValue..";"
			end
		end
	end
	return text
end

return Utilities 
