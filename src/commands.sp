// Copyright (c) 2021 dreae
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#include <sourcemod>
#include "includes/infractions"

void GFLBans_RegisterCommands() {
    AddCommandListener(CommandListener_Gag, "sm_gag");
    AddCommandListener(CommandListener_Mute, "sm_mute");
    AddCommandListener(CommandListener_Silence, "sm_silence");
    AddCommandListener(CommandListener_Ungag, "sm_ungag");
    AddCommandListener(CommandListener_Unmute, "sm_unmute");
    AddCommandListener(CommandListener_Unsilence, "sm_unsilence");
    RegAdminCmd("sm_ban", CommandBan, ADMFLAG_BAN, "sm_ban <target> <minutes|0> [reason]", "gflbans");
    RegAdminCmd("sm_unban", CommandUnban, ADMFLAG_UNBAN, "sm_unban <steamid|ip> [reason]", "gflbans");
}

int GetCommandTargets(int client, const char[] target_string, int[] target_list, int max_targets) {
    char target_name[MAX_TARGET_LENGTH];
    bool tn_is_ml;
    return ProcessTargetString(
        target_string, client, target_list, max_targets, 
        COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS,
        target_name, sizeof(target_name), tn_is_ml);
}

bool ParseCommandArguments(int client, int target_list[MAXPLAYERS], int &target_count, char[] reason, int reason_max, int &time) {
    char arguments[256];
    GetCmdArgString(arguments, sizeof(arguments));

    char target[65];
    int len = BreakString(arguments, target, sizeof(target));

    int result = GetCommandTargets(client, target, target_list, MAXPLAYERS);
    if (result < 0) {
        ReplyToTargetError(client, result);
        return false;
    } else if (result == 0) {
        ReplyToCommand(client, "%t", "No targets found");
        return false;
    }
    target_count = result;

    char s_time[12];
    time = StringToInt(s_time);

    int next_len = BreakString(arguments[len], s_time, sizeof(s_time));
    if (next_len != -1) {
        len += next_len;
    } else {
        len = 0;
        arguments[0] = '\0';
    }
    Format(reason, reason_max, arguments[len]);

    return true;
}

Action HandleChatInfraction(const char[] command, int client, int args, int admin_flags, const InfractionBlock[] blocks, int total_blocks) {
    if (client && !CheckCommandAccess(client, "", admin_flags, true)) {
        return Plugin_Continue;
    }

    if (args < 2) {
        ReplyToCommand(client, "%t", "Infraction Usage", command);
        return Plugin_Stop;
    }

    int target_list[MAXPLAYERS];
    int target_count = -1;
    char reason[128];
    int time = 0;
    if (!ParseCommandArguments(client, target_list, target_count, reason, sizeof(reason), time)) {
        return Plugin_Stop;
    }

    for (int c = 0; c < target_count; c++) {
        GFLBans_ApplyInfraction(client, target_list[c], blocks, total_blocks, time, reason);
    }

    return Plugin_Stop;
}

Action HandleRemoveChatInfraction(int client, int args, int admin_flags, const InfractionBlock[] blocks, int total_blocks) {
    if (client && !CheckCommandAccess(client, "", admin_flags, true)) {
        return Plugin_Continue;
    }
    return Plugin_Stop;
}

public Action CommandListener_Gag(int client, const char[] command, int args) {
    InfractionBlock blocks[] = {Block_Chat};
    return HandleChatInfraction(command, client, args, ADMFLAG_CHAT, blocks, sizeof(blocks));
}

public Action CommandListener_Mute(int client, const char[] command, int args) {
    InfractionBlock blocks[] = {Block_Voice};
    return HandleChatInfraction(command, client, args, ADMFLAG_CHAT, blocks, sizeof(blocks));
}

public Action CommandListener_Silence(int client, const char[] command, int args) {
    InfractionBlock blocks[] = {Block_Chat, Block_Voice};
    return HandleChatInfraction(command, client, args, ADMFLAG_CHAT, blocks, sizeof(blocks));
}

public Action CommandListener_Ungag(int client, const char[] command, int args) {
    InfractionBlock blocks[] = {Block_Chat};
    return HandleRemoveChatInfraction(client, args, ADMFLAG_CHAT, blocks, sizeof(blocks));
}

public Action CommandListener_Unmute(int client, const char[] command, int args) {
    InfractionBlock blocks[] = {Block_Voice};
    return HandleRemoveChatInfraction(client, args, ADMFLAG_CHAT, blocks, sizeof(blocks));
}

public Action CommandListener_Unsilence(int client, const char[] command, int args) {
    InfractionBlock blocks[] = {Block_Chat, Block_Voice};
    return HandleRemoveChatInfraction(client, args, ADMFLAG_CHAT, blocks, sizeof(blocks));
}

public Action CommandBan(int client, int args) {
    if (args < 2) {
        ReplyToCommand(client, "%t", "Infraction Usage", "sm_ban");
        return Plugin_Stop;
    }

    int target_list[MAXPLAYERS];
    int target_count = -1;
    char reason[128];
    int time = 0;
    if (!ParseCommandArguments(client, target_list, target_count, reason, sizeof(reason), time)) {
        return Plugin_Stop;
    }

    if (time == 0 && !CheckCommandAccess(client, "", ADMFLAG_UNBAN, false)) {
        ReplyToCommand(client, "%t", "No PermBan Permission");
    }
    return Plugin_Stop;
}

public Action CommandUnban(int client, int args) {
    return Plugin_Stop;
}