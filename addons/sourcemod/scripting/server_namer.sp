#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>


public Plugin myinfo = {
    name        = "ServerNamer",
    author      = "sheo, TouchMe",
    description = "Changes server hostname according to the current game mode",
    version     = "build_0002",
    url         = "https://github.com/TouchMe-Inc/l4d2_server_namer"
}


ConVar
    g_cvHostname = null,
    g_cvGamemode = null,
    g_cvHostNameTemplate = null,
    g_cvHostNameTemplateFree = null,
    g_cvServerNum = null,
    g_cvCustomHostname = null,
    g_cvCustomGamemode = null
;

StringMap g_smGamemodes = null;


/**
 * Called when the plugin is fully initialized and all known external references are resolved.
 */
public void OnPluginStart()
{
    /*
     * Read config.
     */
    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof(szPath), "configs/server_namer.txt");

    ReadConfig(szPath, g_smGamemodes = new StringMap());

    /*
     * Cvars.
     */
    g_cvHostname = FindConVar("hostname");
    g_cvGamemode = FindConVar("mp_gamemode");
    g_cvHostNameTemplate = CreateConVar("sn_hostname_template", "{hostname} | {gamemode}");
    g_cvHostNameTemplateFree = CreateConVar("sn_hostname_template_free", "*FREE* {hostname}");
    g_cvServerNum = CreateConVar("sn_custom_server_num", "1", "Custom server number. Use {num}");
    g_cvCustomHostname = CreateConVar("sn_custom_hostname", "", "Custom server name. Use {hostname}");
    g_cvCustomGamemode = CreateConVar("sn_custom_gamemode", "", "Custom gamemode name. Use {gamemode}");

    /*
     * Hook Cvar change.
     */
    HookConVarChange(g_cvGamemode, OnCvarChanged);
    HookConVarChange(g_cvCustomHostname, OnCvarChanged);
    HookConVarChange(g_cvCustomGamemode, OnCvarChanged);
    HookConVarChange(g_cvServerNum, OnCvarChanged);
    HookConVarChange(g_cvHostNameTemplate, OnCvarChanged);
    HookConVarChange(g_cvHostNameTemplateFree, OnCvarChanged);
}

void ReadConfig(const char[] szPath, StringMap smGamemodes)
{
    if (!FileExists(szPath)) {
        SetFailState("Couldn't load %s", szPath);
    }

    Handle hGamemodes = CreateKeyValues("Gamemodes");

    if (!FileToKeyValues(hGamemodes, szPath)) {
        SetFailState("Failed to parse keyvalues for %s", szPath);
    }

    if (KvGotoFirstSubKey(hGamemodes, false))
    {
        char szSectionKey[32], szSectionValue[64];

        do
        {
            KvGetSectionName(hGamemodes, szSectionKey, sizeof(szSectionKey));
            KvGetString(hGamemodes, NULL_STRING, szSectionValue, sizeof(szSectionValue));
            smGamemodes.SetString(szSectionKey, szSectionValue);
        } while (KvGotoNextKey(hGamemodes, false));
    }

    delete hGamemodes;
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
    char szCustomHostname[64]; GetConVarString(g_cvCustomHostname, szCustomHostname, sizeof(szCustomHostname));

    if (szCustomHostname[0] == '\0') {
        return;
    }

    ConVar cvTemplate = IsEmptyServer() ? g_cvHostNameTemplateFree : g_cvHostNameTemplate;

    char szTemplate[128]; GetConVarString(cvTemplate, szTemplate, sizeof(szTemplate));
    char szCustomGamemode[32]; GetConVarString(g_cvCustomGamemode, szCustomGamemode, sizeof(szCustomGamemode));

    if (szCustomGamemode[0] == '\0')
    {
        char szGamemode[32];
        GetConVarString(g_cvGamemode, szGamemode, sizeof(szGamemode));

        if (!GetTrieString(g_smGamemodes, szGamemode, szCustomGamemode, sizeof(szCustomGamemode))) {
            strcopy(szCustomGamemode, sizeof(szCustomGamemode), szGamemode);
        }
    }

    char szServerNum[4]; GetConVarString(g_cvServerNum, szServerNum, sizeof(szServerNum));

    ReplaceString(szTemplate, sizeof(szTemplate), "{hostname}", szCustomHostname);
    ReplaceString(szTemplate, sizeof(szTemplate), "{gamemode}", szCustomGamemode);
    ReplaceString(szTemplate, sizeof(szTemplate), "{num}", szServerNum);

    SetConVarString(g_cvHostname, szTemplate);
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
