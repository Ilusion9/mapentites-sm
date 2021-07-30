# Description
Change map entities by classname, name, or hammer id.
- You can remove entities.
- You can add / change / remove entity keyvalues.
- You can add / remove entity outputs.

# Dependencies
- Intmap (include-file) - https://github.com/Ilusion9/intmap-inc-sm

# Examples
```
	"Remove Entities"
	{
		"1"
		{
			"classname"		"weapon_flashbang" // remove by classname
		}
		
		"1"
		{
			"name"		"targetname" // remove by targetname
		}
    
		"1"
		{
			"hammer"		"12345" // remove by hammer id
		}
	}
```

```
	"Keyvalues"
	{
		"1"
		{
			"classname"		"func_tanktrain"
			"keyvalues"
			{
				"1"
				{
					"key"			"spawnflags"
					"value"			"514"
					"add_flags"		"1" // add flags
				}
			}
		}
    
		"1"
		{
			"classname"		"func_tanktrain"
			"keyvalues"
			{
				"1"
				{
					"key"			"spawnflags"
					"value"			"8"
					"remove_flags"		"1" // remove flags
				}
			}
		}
    
		"1"
		{
			"name"		"button38"
			"keyvalues"
			{
				"1"
				{
					"key"			"wait"
					"remove"			"1" // remove this keyvalue
				}
			}
		}
    
		"1"
		{
			"hammer"		"555"
			"keyvalues"
			{
				"1"
				{
					"key"			"wait"
					"value"			"0" // the value will be replaced
				}
			}
		}
	}
```
	"Outputs"
	{
		"1"
		{
			"name"		"button31"
			"outputs"
			{
				"1"
				{
					"key"			"OnPressed"
					"value"			"button30:Kill::0:-1" // add output
				}
				
				"1"
				{
					"key"			"OnPressed"
					"value"			"button29:Kill::0:-1"
					"remove"			"1" // remove this output
				}
			}
		}
	}
