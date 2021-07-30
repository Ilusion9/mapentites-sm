#if defined _mapentities_defined_
#endinput
#endif
#define _mapentities_defined_

/**
 * Returns an output from an entity outputs list
 *
 * @param entity                    Entity index.
 * @param index                     Index in the output list.
 * @param outputName                Buffer to copy the output name.
 * @param outputNameLen             Maximum size of the output buffer.
 * @param targetName                Buffer to copy the target name.
 * @param targetNameLen             Maximum size of the target buffer.
 * @param inputName                 Buffer to copy the input received.
 * @param inputNameLen              Maximum size of the input buffer.
 * @param params                    Buffer to copy the parameters received.
 * @param paramsLen                 Maximum size of the parameters buffer.
 * @param outputDelay               Delay of the output
 * @param outputOnce                True if the output has 'Only Once' flag enabled.
 * @return                          True if the output has been returned.
 */
native bool GetEntityOutput(int entity, int index, char[] outputName, int outputNameLen, char[] targetName, int targetNameLen, char[] inputName, int inputNameLen, char[] params, int paramsLen, float& outputDelay, bool& outputOnce);

/**
 * Returns the entity outputs count.
 *
 * @param entity                Entity index.
 * @return                      The entity outputs count.
 */
native int GetEntityOutputsCount(int entity);

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin __pl_mapentities_defined_ = 
{
	name = "mapentities",
	file = "mapentities.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_mapentities_SetNTVOptional()
{
	MarkNativeAsOptional("GetEntityOutput");
	MarkNativeAsOptional("GetEntityOutputsCount");
}
#endif