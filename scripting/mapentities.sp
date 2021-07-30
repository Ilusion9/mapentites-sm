#pragma semicolon 1
#pragma dynamic 1048576
#pragma newdecls required

#include <sourcemod>
#include <regex>
#include <intmap>

public Plugin myinfo =
{
	name = "Output Info",
	author = "Ilusion9",
	description = "Get entities outputs.",
	version = "1.1",
	url = "https://github.com/Ilusion9/"
};

#define KV_REMOVE                  (1 << 0)
#define KV_ADD_FLAGS               (1 << 1)
#define KV_REMOVE_FLAGS            (1 << 2)

enum KeyValueType
{
	KeyValueType_None,
	KeyValueType_Replace,
	KeyValueType_Remove
}

enum struct OutputInfo
{
	bool outputOnce;
	char outputName[256];
	char targetName[256];
	char inputName[256];
	char params[256];
	float outputDelay;
}

enum struct RangeInfo
{
	int rangeStart;
	int rangeEnd;
}

enum struct KvInfo
{
	int flags;
	char key[256];
	char value[256];
}

enum struct InitKvInfo
{
	char key[256];
	char value[256];
}

ArrayList g_List_OnLevelInit;
ArrayList g_List_EntityOutputs;
ArrayList g_List_ChangeOutputs;
ArrayList g_List_ChangeKeyValues;

StringMap g_Map_ChangeOutputs;
StringMap g_Map_RemoveEntities;
StringMap g_Map_ChangeKeyValues;

IntMap g_Map_EntityOutputs;
Regex g_Regex_KeyValue;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("GetEntityOutput", Native_GetEntityOutput);		
	CreateNative("GetEntityOutputsCount", Native_GetEntityOutputsCount);
	
	RegPluginLibrary("mapentities");
}

public void OnPluginStart()
{
	g_List_OnLevelInit = new ArrayList(sizeof(InitKvInfo));
	g_List_EntityOutputs = new ArrayList(sizeof(OutputInfo));
	g_List_ChangeOutputs = new ArrayList(sizeof(KvInfo));
	g_List_ChangeKeyValues = new ArrayList(sizeof(KvInfo));
	
	g_Map_ChangeOutputs = new StringMap();
	g_Map_RemoveEntities = new StringMap();
	g_Map_ChangeKeyValues = new StringMap();
	
	g_Map_EntityOutputs = new IntMap();
}

public void OnMapEnd()
{
	ClearArrayList(g_List_OnLevelInit);
	ClearArrayList(g_List_EntityOutputs);
	ClearArrayList(g_List_ChangeOutputs);
	ClearArrayList(g_List_ChangeKeyValues);
	
	ClearStringMap(g_Map_ChangeOutputs);
	ClearStringMap(g_Map_RemoveEntities);
	ClearStringMap(g_Map_ChangeKeyValues);
	
	ClearIntMap(g_Map_EntityOutputs);
}

public Action OnLevelInit(const char[] mapName, char mapEntities[2097152])
{
	ClearArrayList(g_List_OnLevelInit);
	ClearArrayList(g_List_EntityOutputs);
	ClearArrayList(g_List_ChangeOutputs);
	ClearArrayList(g_List_ChangeKeyValues);
	
	ClearStringMap(g_Map_ChangeOutputs);
	ClearStringMap(g_Map_RemoveEntities);
	ClearStringMap(g_Map_ChangeKeyValues);
	
	ClearIntMap(g_Map_EntityOutputs);
	delete g_Regex_KeyValue;
	
	char path[PLATFORM_MAX_PATH];
	KeyValues kv = new KeyValues("Map Config");
	
	GetCurrentMap(path, sizeof(path));
	BuildPath(Path_SM, path, sizeof(path), "configs/mapentities/%s.cfg", path);
	
	if (kv.ImportFromFile(path))
	{
		if (kv.JumpToKey("Remove Entities"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					char key[256];
					kv.GetString("classname", key, sizeof(key));
					
					if (key[0])
					{
						StringToLower(key);
						Format(key, sizeof(key), "c:%s", key);
						
						g_Map_RemoveEntities.SetValue(key, true);
					}
					else
					{
						kv.GetString("name", key, sizeof(key));
						if (key[0])
						{
							StringToLower(key);
							Format(key, sizeof(key), "n:%s", key);
							
							g_Map_RemoveEntities.SetValue(key, true);
						}
						else
						{
							kv.GetString("hammer", key, sizeof(key));
							if (key[0])
							{
								StringToLower(key);
								Format(key, sizeof(key), "h:%s", key);
								
								g_Map_RemoveEntities.SetValue(key, true);
							}
						}
					}
					
				} while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
		
		if (kv.JumpToKey("Keyvalues"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					char key[256];
					kv.GetString("classname", key, sizeof(key));
					
					if (key[0])
					{
						StringToLower(key);
						Format(key, sizeof(key), "c:%s", key);
					}
					else
					{
						kv.GetString("name", key, sizeof(key));
						if (key[0])
						{
							StringToLower(key);
							Format(key, sizeof(key), "n:%s", key);
						}
						else
						{
							kv.GetString("hammer", key, sizeof(key));
							if (key[0])
							{
								StringToLower(key);
								Format(key, sizeof(key), "h:%s", key);
							}
						}
					}
					
					if (kv.JumpToKey("keyvalues"))
					{
						RangeInfo rangeInfo;
						rangeInfo.rangeStart = g_List_ChangeKeyValues.Length;
						
						if (kv.GotoFirstSubKey(false))
						{
							do
							{
								KvInfo kvInfo;
								kv.GetString("key", kvInfo.key, sizeof(KvInfo::key));
								kv.GetString("value", kvInfo.value, sizeof(KvInfo::value));
								
								kvInfo.flags = 0;
								if (view_as<bool>(kv.GetNum("remove", 0)))
								{
									kvInfo.flags |= KV_REMOVE;
								}
								
								if (view_as<bool>(kv.GetNum("add_flags", 0)))
								{
									kvInfo.flags |= KV_ADD_FLAGS;
								}
								
								if (view_as<bool>(kv.GetNum("remove_flags", 0)))
								{
									kvInfo.flags |= KV_REMOVE_FLAGS;
								}
								
								g_List_ChangeKeyValues.PushArray(kvInfo);
								
							} while (kv.GotoNextKey(false));
							kv.GoBack();
						}
						
						if (g_List_ChangeKeyValues.Length != rangeInfo.rangeStart)
						{
							rangeInfo.rangeEnd = g_List_ChangeKeyValues.Length;
							g_Map_ChangeKeyValues.SetArray(key, rangeInfo, sizeof(RangeInfo));
						}
						
						kv.GoBack();
					}
				
				} while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
		
		if (kv.JumpToKey("Outputs"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					char key[256];
					kv.GetString("classname", key, sizeof(key));
					
					if (key[0])
					{
						StringToLower(key);
						Format(key, sizeof(key), "c:%s", key);
					}
					else
					{
						kv.GetString("name", key, sizeof(key));
						if (key[0])
						{
							StringToLower(key);
							Format(key, sizeof(key), "n:%s", key);
						}
						else
						{
							kv.GetString("hammer", key, sizeof(key));
							if (key[0])
							{
								StringToLower(key);
								Format(key, sizeof(key), "h:%s", key);
							}
						}
					}
					
					if (kv.JumpToKey("outputs"))
					{
						RangeInfo rangeInfo;
						rangeInfo.rangeStart = g_List_ChangeOutputs.Length;
						
						if (kv.GotoFirstSubKey(false))
						{
							do
							{
								KvInfo kvInfo;
								kv.GetString("key", kvInfo.key, sizeof(KvInfo::key));
								
								kv.GetString("value", kvInfo.value, sizeof(KvInfo::value));
								ReplaceString(kvInfo.value, sizeof(KvInfo::value), ":", "\e");
								
								kvInfo.flags = 0;
								if (view_as<bool>(kv.GetNum("remove", 0)))
								{
									kvInfo.flags |= KV_REMOVE;
								}
								
								g_List_ChangeOutputs.PushArray(kvInfo);
								
							} while (kv.GotoNextKey(false));
							kv.GoBack();
						}
						
						if (g_List_ChangeOutputs.Length != rangeInfo.rangeStart)
						{
							rangeInfo.rangeEnd = g_List_ChangeOutputs.Length;
							g_Map_ChangeOutputs.SetArray(key, rangeInfo, sizeof(RangeInfo));
						}
						
						kv.GoBack();
					}
				
				} while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
	}
	
	delete kv;
	int start = 0;
	int current = 0;
	
	while ((start = FindCharInString(mapEntities[current], '{')) != -1)
	{
		current += start;
		
		int length;
		if ((length = FindCharInString(mapEntities[current], '}')) == -1)
		{
			break;
		}
		
		length += 2;
		char[] buffer = new char[length + 1];
		strcopy(buffer, length, mapEntities[current]);
		
		// get entity classname
		char classname[256];
		g_Regex_KeyValue = new Regex("\"(classname)\"\\s+\"([^\"]*)\"", PCRE_CASELESS);
		
		if (g_Regex_KeyValue.Match(buffer) > 0)
		{
			g_Regex_KeyValue.GetSubString(2, classname, sizeof(classname));
			if (classname[0])
			{
				StringToLower(classname);
				Format(classname, sizeof(classname), "c:%s", classname);
			}
		}
		
		delete g_Regex_KeyValue;
		
		// invalid classname
		if (!classname[2])
		{
			Format(mapEntities[current], sizeof(mapEntities) - current, "%s", mapEntities[current + length]);
			continue;
		}
		
		// get entity targetname
		char entityName[256];
		g_Regex_KeyValue = new Regex("\"(targetname)\"\\s+\"([^\"]*)\"", PCRE_CASELESS);
		
		if (g_Regex_KeyValue.Match(buffer) > 0)
		{
			g_Regex_KeyValue.GetSubString(2, entityName, sizeof(entityName));
			if (entityName[0])
			{
				StringToLower(entityName);
				Format(entityName, sizeof(entityName), "n:%s", entityName);
			}
		}
		
		delete g_Regex_KeyValue;
		
		// get entity hammerId
		char hammerId[256];
		g_Regex_KeyValue = new Regex("\"(hammerid)\"\\s+\"([^\"]*)\"", PCRE_CASELESS);
		
		if (g_Regex_KeyValue.Match(buffer) > 0)
		{
			g_Regex_KeyValue.GetSubString(2, hammerId, sizeof(hammerId));
			if (hammerId[0])
			{
				Format(hammerId, sizeof(hammerId), "h:%s", hammerId);
			}
		}
		
		delete g_Regex_KeyValue;
		
		// remove entity
		if (g_Map_RemoveEntities.Size)
		{
			// remove by classname
			if (classname[2])
			{
				bool removeEntity;
				if (g_Map_RemoveEntities.GetValue(classname, removeEntity))
				{
					Format(mapEntities[current], sizeof(mapEntities) - current, "%s", mapEntities[current + length]);
					continue;
				}
			}
			
			// remove by targetname
			if (entityName[2])
			{
				bool removeEntity;
				if (g_Map_RemoveEntities.GetValue(entityName, removeEntity))
				{
					Format(mapEntities[current], sizeof(mapEntities) - current, "%s", mapEntities[current + length]);
					continue;
				}
			}
			
			// remove by hammerId
			if (hammerId[2])
			{
				bool removeEntity;
				if (g_Map_RemoveEntities.GetValue(hammerId, removeEntity))
				{
					Format(mapEntities[current], sizeof(mapEntities) - current, "%s", mapEntities[current + length]);
					continue;	
				}
			}
		}
		
		// get entity keyvalues
		InitKvInfo initKvInfo;
		g_Regex_KeyValue = new Regex("\"([^\"]+)\"\\s+\"([^\"]*)\"", PCRE_CASELESS);
		
		for (int i = 0; g_Regex_KeyValue.Match(buffer[i]) > 0; i += g_Regex_KeyValue.MatchOffset())
		{
			g_Regex_KeyValue.GetSubString(1, initKvInfo.key, sizeof(InitKvInfo::key));			
			g_Regex_KeyValue.GetSubString(2, initKvInfo.value, sizeof(InitKvInfo::value));
			g_List_OnLevelInit.PushArray(initKvInfo);
		}
		
		delete g_Regex_KeyValue;
		
		RangeInfo rangeInfo;		
		rangeInfo.rangeStart = 0;
		rangeInfo.rangeEnd = 0;
		
		// change entity keyvalues
		if (g_Map_ChangeKeyValues.Size)
		{
			if (g_Map_ChangeKeyValues.GetArray(classname, rangeInfo, sizeof(RangeInfo)))
			{
				KvInfo kvInfo;
				for (int i = rangeInfo.rangeStart; i < rangeInfo.rangeEnd; i++)
				{
					g_List_ChangeKeyValues.GetArray(i, kvInfo);
					if (view_as<bool>(kvInfo.flags & KV_REMOVE))
					{
						for (int j = g_List_OnLevelInit.Length - 1; j >= 0; j--)
						{
							g_List_OnLevelInit.GetArray(j, initKvInfo);
							if (StrEqual(kvInfo.key, initKvInfo.key, true))
							{
								g_List_OnLevelInit.Erase(j);
							}
						}
					}
					else
					{
						bool keyReplaced = false;
						for (int j = 0; j < g_List_OnLevelInit.Length; j++)
						{
							g_List_OnLevelInit.GetArray(j, initKvInfo);
							if (StrEqual(kvInfo.key, initKvInfo.key, true))
							{
								if (view_as<bool>(kvInfo.flags & KV_ADD_FLAGS))
								{
									int value = StringToInt(initKvInfo.value);
									value |= StringToInt(kvInfo.value);
									Format(initKvInfo.value, sizeof(InitKvInfo::value), "%d", value);
								}
								else if (view_as<bool>(kvInfo.flags & KV_REMOVE_FLAGS))
								{
									int value = StringToInt(initKvInfo.value);
									value &= ~StringToInt(kvInfo.value);
									Format(initKvInfo.value, sizeof(InitKvInfo::value), "%d", value);
								}
								else
								{
									strcopy(initKvInfo.value, sizeof(InitKvInfo::value), kvInfo.value);
								}
								
								g_List_OnLevelInit.SetArray(j, initKvInfo);
								keyReplaced = true;
							}
						}
						
						if (!keyReplaced && !view_as<bool>(kvInfo.flags & KV_REMOVE_FLAGS))
						{
							strcopy(initKvInfo.key, sizeof(InitKvInfo::key), kvInfo.key);
							strcopy(initKvInfo.value, sizeof(InitKvInfo::value), kvInfo.value);
							g_List_OnLevelInit.PushArray(initKvInfo);
						}
					}
				}
			}
			
			if (g_Map_ChangeKeyValues.GetArray(entityName, rangeInfo, sizeof(RangeInfo)))
			{
				KvInfo kvInfo;
				for (int i = rangeInfo.rangeStart; i < rangeInfo.rangeEnd; i++)
				{
					g_List_ChangeKeyValues.GetArray(i, kvInfo);
					if (view_as<bool>(kvInfo.flags & KV_REMOVE))
					{
						for (int j = g_List_OnLevelInit.Length - 1; j >= 0; j--)
						{
							g_List_OnLevelInit.GetArray(j, initKvInfo);
							if (StrEqual(kvInfo.key, initKvInfo.key, true))
							{
								g_List_OnLevelInit.Erase(j);
							}
						}
					}
					else
					{
						bool keyReplaced = false;
						for (int j = 0; j < g_List_OnLevelInit.Length; j++)
						{
							g_List_OnLevelInit.GetArray(j, initKvInfo);
							if (StrEqual(kvInfo.key, initKvInfo.key, true))
							{
								if (view_as<bool>(kvInfo.flags & KV_ADD_FLAGS))
								{
									int value = StringToInt(initKvInfo.value);
									value |= StringToInt(kvInfo.value);
									Format(initKvInfo.value, sizeof(InitKvInfo::value), "%d", value);
								}
								else if (view_as<bool>(kvInfo.flags & KV_REMOVE_FLAGS))
								{
									int value = StringToInt(initKvInfo.value);
									value &= ~StringToInt(kvInfo.value);
									Format(initKvInfo.value, sizeof(InitKvInfo::value), "%d", value);
								}
								else
								{
									strcopy(initKvInfo.value, sizeof(InitKvInfo::value), kvInfo.value);
								}
								
								g_List_OnLevelInit.SetArray(j, initKvInfo);
								keyReplaced = true;
							}
						}
						
						if (!keyReplaced && !view_as<bool>(kvInfo.flags & KV_REMOVE_FLAGS))
						{
							strcopy(initKvInfo.key, sizeof(InitKvInfo::key), kvInfo.key);
							strcopy(initKvInfo.value, sizeof(InitKvInfo::value), kvInfo.value);
							g_List_OnLevelInit.PushArray(initKvInfo);
						}
					}
				}
			}
			
			if (g_Map_ChangeKeyValues.GetArray(hammerId, rangeInfo, sizeof(RangeInfo)))
			{
				KvInfo kvInfo;
				for (int i = rangeInfo.rangeStart; i < rangeInfo.rangeEnd; i++)
				{
					g_List_ChangeKeyValues.GetArray(i, kvInfo);
					if (view_as<bool>(kvInfo.flags & KV_REMOVE))
					{
						for (int j = g_List_OnLevelInit.Length - 1; j >= 0; j--)
						{
							g_List_OnLevelInit.GetArray(j, initKvInfo);
							if (StrEqual(kvInfo.key, initKvInfo.key, true))
							{
								g_List_OnLevelInit.Erase(j);
							}
						}
					}
					else
					{
						bool keyReplaced = false;
						for (int j = 0; j < g_List_OnLevelInit.Length; j++)
						{
							g_List_OnLevelInit.GetArray(j, initKvInfo);
							if (StrEqual(kvInfo.key, initKvInfo.key, true))
							{
								if (view_as<bool>(kvInfo.flags & KV_ADD_FLAGS))
								{
									int value = StringToInt(initKvInfo.value);
									value |= StringToInt(kvInfo.value);
									Format(initKvInfo.value, sizeof(InitKvInfo::value), "%d", value);
								}
								else if (view_as<bool>(kvInfo.flags & KV_REMOVE_FLAGS))
								{
									int value = StringToInt(initKvInfo.value);
									value &= ~StringToInt(kvInfo.value);
									Format(initKvInfo.value, sizeof(InitKvInfo::value), "%d", value);
								}
								else
								{
									strcopy(initKvInfo.value, sizeof(InitKvInfo::value), kvInfo.value);
								}
								
								g_List_OnLevelInit.SetArray(j, initKvInfo);
								keyReplaced = true;
							}
						}
						
						if (!keyReplaced && !view_as<bool>(kvInfo.flags & KV_REMOVE_FLAGS))
						{
							strcopy(initKvInfo.key, sizeof(InitKvInfo::key), kvInfo.key);
							strcopy(initKvInfo.value, sizeof(InitKvInfo::value), kvInfo.value);
							g_List_OnLevelInit.PushArray(initKvInfo);
						}
					}
				}
			}
		}
		
		// change entity outputs
		if (g_Map_ChangeOutputs.Size)
		{
			if (g_Map_ChangeOutputs.GetArray(classname, rangeInfo, sizeof(RangeInfo)))
			{
				KvInfo kvInfo;
				for (int i = rangeInfo.rangeStart; i < rangeInfo.rangeEnd; i++)
				{
					g_List_ChangeOutputs.GetArray(i, kvInfo);
					if (view_as<bool>(kvInfo.flags & KV_REMOVE))
					{
						for (int j = g_List_OnLevelInit.Length - 1; j >= 0; j--)
						{
							g_List_OnLevelInit.GetArray(j, initKvInfo);
							if (StrEqual(kvInfo.key, initKvInfo.key, true) && StrEqual(kvInfo.value, initKvInfo.value, true))
							{
								g_List_OnLevelInit.Erase(j);
							}
						}
					}
					else
					{
						strcopy(initKvInfo.key, sizeof(InitKvInfo::key), kvInfo.key);
						strcopy(initKvInfo.value, sizeof(InitKvInfo::value), kvInfo.value);
						g_List_OnLevelInit.PushArray(initKvInfo);
					}
				}
			}
			
			if (g_Map_ChangeOutputs.GetArray(entityName, rangeInfo, sizeof(RangeInfo)))
			{
				KvInfo kvInfo;
				for (int i = rangeInfo.rangeStart; i < rangeInfo.rangeEnd; i++)
				{
					g_List_ChangeOutputs.GetArray(i, kvInfo);
					if (view_as<bool>(kvInfo.flags & KV_REMOVE))
					{
						for (int j = g_List_OnLevelInit.Length - 1; j >= 0; j--)
						{
							g_List_OnLevelInit.GetArray(j, initKvInfo);
							if (StrEqual(kvInfo.key, initKvInfo.key, true) && StrEqual(kvInfo.value, initKvInfo.value, true))
							{
								g_List_OnLevelInit.Erase(j);
							}
						}
					}
					else
					{
						strcopy(initKvInfo.key, sizeof(InitKvInfo::key), kvInfo.key);
						strcopy(initKvInfo.value, sizeof(InitKvInfo::value), kvInfo.value);
						g_List_OnLevelInit.PushArray(initKvInfo);
					}
				}
			}
			
			if (g_Map_ChangeOutputs.GetArray(hammerId, rangeInfo, sizeof(RangeInfo)))
			{
				KvInfo kvInfo;
				for (int i = rangeInfo.rangeStart; i < rangeInfo.rangeEnd; i++)
				{
					g_List_ChangeOutputs.GetArray(i, kvInfo);
					if (view_as<bool>(kvInfo.flags & KV_REMOVE))
					{
						for (int j = g_List_OnLevelInit.Length - 1; j >= 0; j--)
						{
							g_List_OnLevelInit.GetArray(j, initKvInfo);
							if (StrEqual(kvInfo.key, initKvInfo.key, true) && StrEqual(kvInfo.value, initKvInfo.value, true))
							{
								g_List_OnLevelInit.Erase(j);
							}
						}
					}
					else
					{
						strcopy(initKvInfo.key, sizeof(InitKvInfo::key), kvInfo.key);
						strcopy(initKvInfo.value, sizeof(InitKvInfo::value), kvInfo.value);
						g_List_OnLevelInit.PushArray(initKvInfo);
					}
				}
			}
		}
		
		// update entity keyvalues in mapEntities
		int entitySize = (g_List_OnLevelInit.Length + 1) * (sizeof(KvInfo::key) + sizeof(KvInfo::value));
		char[] entityKeys = new char[entitySize];
		
		Format(entityKeys, entitySize, "{\n");
		for (int i = 0; i < g_List_OnLevelInit.Length; i++)
		{
			g_List_OnLevelInit.GetArray(i, initKvInfo);
			Format(entityKeys, entitySize, "%s\"%s\" \"%s\"\n", entityKeys, initKvInfo.key, initKvInfo.value);
		}
		
		Format(entityKeys, entitySize, "%s}\n", entityKeys);
		Format(mapEntities[current], sizeof(mapEntities) - current, "%s%s", entityKeys, mapEntities[current + length]);
		current += strlen(entityKeys);
		
		// save entity outputs
		OutputInfo outputInfo;
		rangeInfo.rangeStart = g_List_EntityOutputs.Length;
		
		for (int i = 0; i < g_List_OnLevelInit.Length; i++)
		{
			g_List_OnLevelInit.GetArray(i, initKvInfo);
			
			// split output params
			char splitOutput[5][256];
			if (ExplodeString(initKvInfo.value, "\e", splitOutput, sizeof(splitOutput), sizeof(splitOutput[])) != sizeof(splitOutput))
			{
				continue;
			}
						
			Format(outputInfo.outputName, sizeof(OutputInfo::outputName), initKvInfo.key);
			Format(outputInfo.targetName, sizeof(OutputInfo::targetName), splitOutput[0]);
			Format(outputInfo.inputName, sizeof(OutputInfo::inputName), splitOutput[1]);
			Format(outputInfo.params, sizeof(OutputInfo::params), splitOutput[2]);
			outputInfo.outputDelay = StringToFloat(splitOutput[3]);
			outputInfo.outputOnce = StringToInt(splitOutput[4]) > 0;
			
			g_List_EntityOutputs.PushArray(outputInfo);
		}
		
		if (rangeInfo.rangeStart != g_List_EntityOutputs.Length)
		{
			rangeInfo.rangeEnd = g_List_EntityOutputs.Length;
			view_as<StringMap>(g_Map_EntityOutputs).SetArray(hammerId[2], rangeInfo, sizeof(RangeInfo));
		}
		
		delete g_Regex_KeyValue;
		ClearArrayList(g_List_OnLevelInit);
	}
	
	ClearArrayList(g_List_ChangeOutputs);
	ClearArrayList(g_List_ChangeKeyValues);
	
	ClearStringMap(g_Map_ChangeOutputs);
	ClearStringMap(g_Map_RemoveEntities);
	ClearStringMap(g_Map_ChangeKeyValues);
	
	return Plugin_Changed;
}

public int Native_GetEntityOutput(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid entity index %d", entity);
	}
	
	int outputIndex = GetNativeCell(2);
	if (outputIndex < 0)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid output index %d", outputIndex);
	}
	
	RangeInfo rangeInfo;
	int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
	
	if (!g_Map_EntityOutputs.GetArray(hammerId, rangeInfo, sizeof(RangeInfo)))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid output index %d", outputIndex);
	}
	
	if (outputIndex + rangeInfo.rangeStart >= rangeInfo.rangeEnd)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid output index %d", outputIndex);
	}
	
	OutputInfo outputInfo;
	g_List_EntityOutputs.GetArray(outputIndex + rangeInfo.rangeStart, outputInfo);
	
	SetNativeString(3, outputInfo.outputName, GetNativeCell(4));
	SetNativeString(5, outputInfo.targetName, GetNativeCell(6));
	SetNativeString(7, outputInfo.inputName, GetNativeCell(8));
	SetNativeString(9, outputInfo.params, GetNativeCell(10));
	SetNativeCellRef(11, outputInfo.outputDelay);
	SetNativeCellRef(12, outputInfo.outputOnce);
	
	return true;
}

public int Native_GetEntityOutputsCount(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);
	if (!IsValidEntity(entity))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid entity index %d", entity);
	}
	
	RangeInfo rangeInfo;
	int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
	
	if (!g_Map_EntityOutputs.GetArray(hammerId, rangeInfo, sizeof(RangeInfo)))
	{
		return 0;
	}
	
	return rangeInfo.rangeEnd - rangeInfo.rangeStart;
}

void StringToLower(char[] buffer)
{
	for (int i = 0; buffer[i]; i++)
	{
		buffer[i] = CharToLower(buffer[i]);
	}
}

void ClearIntMap(IntMap &map)
{
	delete map;
	map = new IntMap();
}

void ClearStringMap(StringMap &map)
{
	delete map;
	map = new StringMap();
}

void ClearArrayList(ArrayList &array)
{
	int blockSize = array.BlockSize;
	delete array;
	array = new ArrayList(blockSize);
}