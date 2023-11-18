#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>


public Plugin myinfo =
{
	name = "ServerNamer",
	author = "TouchMe",
	description = "Changes server hostname according to the current game mode",
	version = "build0000",
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

Handle g_hGamemodeList = INVALID_HANDLE;


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
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvHostname = FindConVar("hostname");
	g_cvGamemode = FindConVar("mp_gamemode");

	// Reg cvars
	g_cvCustomHostname = CreateConVar("sn_custom_hostname", "", "Main server name.");
	g_cvCustomGamemode = CreateConVar("sn_custom_gamemode", "", "Main server name.");
	g_cvHostNameTemplate = CreateConVar("sn_hostname_template", "{hostname} | {gamemode}");
	g_cvHostNameTemplateFree = CreateConVar("sn_hostname_template_free", "{hostname} *FREE*");

	// Hooks
	HookConVarChange(g_cvGamemode, OnCvarChanged);
	HookConVarChange(g_cvCustomHostname, OnCvarChanged);
	HookConVarChange(g_cvCustomGamemode, OnCvarChanged);
	HookConVarChange(g_cvHostNameTemplate, OnCvarChanged);
	HookConVarChange(g_cvHostNameTemplateFree, OnCvarChanged);

	FillGamemode(g_hGamemodeList = CreateTrie());

	UpdateServerName();
}

public void OnPluginEnd() {
	CloseHandle(g_hGamemodeList);
}

public void OnCvarChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue) {
	UpdateServerName();
}

public void OnClientConnected(int client) {
	UpdateServerName();
}

public void OnClientDisconnect_Post(int client) {
	UpdateServerName();
}

public void OnConfigsExecuted() {
	UpdateServerName();
}

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
		GetTrieString(g_hGamemodeList, sGamemode, sCustomGamemode, sizeof(sCustomGamemode));
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

void FillGamemode(Handle hGamemodeList)
{
	SetTrieString(hGamemodeList, "versus", "Versus");
	SetTrieString(hGamemodeList, "coop", "Campaign");
	SetTrieString(hGamemodeList, "survival", "Survival");
	SetTrieString(hGamemodeList, "scavenge", "Scavenge");
	SetTrieString(hGamemodeList, "mutation12", "Realism Versus");
	SetTrieString(hGamemodeList, "realism", "Realism");
	SetTrieString(hGamemodeList, "mutation13", "Follow the Liter");
	SetTrieString(hGamemodeList, "community4", "Nightmare");
	SetTrieString(hGamemodeList, "community1", "Special Delivery");
	SetTrieString(hGamemodeList, "community2", "Flu Season");
	SetTrieString(hGamemodeList, "community5", "Death`s Door");
	SetTrieString(hGamemodeList, "gunbrain", "GunBrain");
	SetTrieString(hGamemodeList, "l4d1coop", "L4D1 Campaign");
	SetTrieString(hGamemodeList, "mutation10", "Room For One");
	SetTrieString(hGamemodeList, "mutation14", "Gib Fest");
	SetTrieString(hGamemodeList, "mutation16", "Hunting Party");
	SetTrieString(hGamemodeList, "mutation2", "Headshot!");
	SetTrieString(hGamemodeList, "mutation20", "Healing Gnome");
	SetTrieString(hGamemodeList, "mutation3", "Bleed Out");
	SetTrieString(hGamemodeList, "mutation4", "Hard Eight");
	SetTrieString(hGamemodeList, "mutation5", "Four Swordsmen");
	SetTrieString(hGamemodeList, "mutation7", "Chainsaw Massacre");
	SetTrieString(hGamemodeList, "mutation8", "Iron Man");
	SetTrieString(hGamemodeList, "mutation9", "Last Gnome On Earth");
	SetTrieString(hGamemodeList, "holdout", "Holdout");
	SetTrieString(hGamemodeList, "dash", "Dash");
	SetTrieString(hGamemodeList, "shootzones", "ShootZones");
	SetTrieString(hGamemodeList, "mutation15", "Versus Survival");
	SetTrieString(hGamemodeList, "community3", "Riding My Survivor");
	SetTrieString(hGamemodeList, "community6", "Confogl mutation");
	SetTrieString(hGamemodeList, "l4d1vs", "L4D1 Versus");
	SetTrieString(hGamemodeList, "mutation11", "Healthpackalypse");
	SetTrieString(hGamemodeList, "mutation18", "Bleed Out Versus");
	SetTrieString(hGamemodeList, "mutation19", "Taaannnk!!");
}
