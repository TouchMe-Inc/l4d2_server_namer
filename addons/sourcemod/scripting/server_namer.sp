#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>


public Plugin myinfo = {
	name = "ServerNamer",
	author = "sheo, TouchMe",
	description = "Changes server hostname according to the current game mode",
	version = "build_0001",
	url = "https://github.com/TouchMe-Inc/l4d2_server_namer"
}


ConVar
	g_cvHostname = null,
	g_cvGamemode = null,
	g_cvCustomHostname = null,
	g_cvCustomGamemode = null,
	g_cvHostNameTemplate = null,
	g_cvHostNameTemplateFree = null
;

Handle  g_hGamemodes = INVALID_HANDLE;


/**
 * Called before OnPluginStart.
 *
 * @param myself            Handle to the plugin.
 * @param late              Whether or not the plugin was loaded "late" (after map load).
 * @param error             Error message buffer in case load failed.
 * @param err_max           Maximum number of characters for error message buffer.
 * @return                  APLRes_Success | APLRes_SilentFailure.
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

/**
 * Called when the plugin is fully initialized and all known external references are resolved.
 */
public void OnPluginStart()
{
	/*
	 * Cvars.
	 */
	g_cvHostname = FindConVar("hostname");
	g_cvGamemode = FindConVar("mp_gamemode");
	g_cvCustomHostname = CreateConVar("sn_custom_hostname", "", "Custom server name.");
	g_cvCustomGamemode = CreateConVar("sn_custom_gamemode", "", "Custom gamemode name.");
	g_cvHostNameTemplate = CreateConVar("sn_hostname_template", "{hostname} | {gamemode}");
	g_cvHostNameTemplateFree = CreateConVar("sn_hostname_template_free", "*FREE* {hostname}");

	/*
	 * Hook Cvar change.
	 */
	HookConVarChange(g_cvGamemode, OnCvarChanged);
	HookConVarChange(g_cvCustomHostname, OnCvarChanged);
	HookConVarChange(g_cvCustomGamemode, OnCvarChanged);
	HookConVarChange(g_cvHostNameTemplate, OnCvarChanged);
	HookConVarChange(g_cvHostNameTemplateFree, OnCvarChanged);

	/*
	 * Read config.
	 */
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/server_namer.txt");
	
	if (!FileExists(sPath)) {
		SetFailState("Couldn't load %s", sPath);
	}

	Handle hGamemodes = CreateKeyValues("Gamemodes");

 	if (!FileToKeyValues(hGamemodes, sPath)) {
		SetFailState("Failed to parse keyvalues for %s", sPath);
	}

	g_hGamemodes = CreateTrie();

	if (KvGotoFirstSubKey(hGamemodes, false))
	{
		char sSectionKey[32], sSectionValue[64];

		do
		{
			KvGetSectionName(hGamemodes, sSectionKey, sizeof(sSectionKey));
			KvGetString(hGamemodes, NULL_STRING, sSectionValue, sizeof(sSectionValue));
			SetTrieString(g_hGamemodes, sSectionKey, sSectionValue);
		} while (KvGotoNextKey(hGamemodes, false));
	}
}

/**
 * If dependent cvars have been updated, update the server name.
 */
public void OnCvarChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue) {
	UpdateServerName();
}

/**
 * Update the server name if the player has joined the server.
 */
public void OnClientConnected(int iClient) {
	UpdateServerName();
}

/**
 * Update the server name if the player has left the server.
 */
public void OnClientDisconnect_Post(int iClient) {
	UpdateServerName();
}

/**
 * We define a server name template, and then set a new server name.
 */
void UpdateServerName()
{
	char sCustomHostname[64]; GetConVarString(g_cvCustomHostname, sCustomHostname, sizeof(sCustomHostname));

	if (sCustomHostname[0] == '\0') {
		return;
	}

	ConVar cvTemplate = IsEmptyServer() ? g_cvHostNameTemplateFree : g_cvHostNameTemplate;

	char sTemplate[128]; GetConVarString(cvTemplate, sTemplate, sizeof(sTemplate));
	char sCustomGamemode[32]; GetConVarString(g_cvCustomGamemode, sCustomGamemode, sizeof(sCustomGamemode));

	if (sCustomGamemode[0] == '\0')
	{
		char sGamemode[32]; GetConVarString(g_cvGamemode, sGamemode, sizeof(sGamemode));
		if (!GetTrieString(g_hGamemodes, sGamemode, sCustomGamemode, sizeof(sCustomGamemode))) {
			strcopy(sCustomGamemode, sizeof(sCustomGamemode), sGamemode);
		}
	}

	ReplaceString(sTemplate, sizeof(sTemplate), "{hostname}", sCustomHostname);
	ReplaceString(sTemplate, sizeof(sTemplate), "{gamemode}", sCustomGamemode);

	SetConVarString(g_cvHostname, sTemplate);
}

bool IsEmptyServer()
{
	for(int iClient = 1; iClient <= MaxClients; iClient ++)
	{
		if (IsClientConnected(iClient) && !IsFakeClient(iClient)) {
			return false;
		}
	}

	return true;
}
